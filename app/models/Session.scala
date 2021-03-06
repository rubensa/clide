package models

import js._
import isabelle._
import scala.actors.Actor._
import play.api.libs.json._
import scala.io.Source
import play.api.Logger
import java.lang.Throwable
import isabelle.Thy_Info
import play.api.cache.Cache

/**
 * Provides a Session interface to the client
 **/
class Session(project: Project) extends JSConnector {    
  /**
   * The list of currently opened documents
   */
  val docs = scala.collection.mutable.Map[Document.Node.Name,RemoteDocumentModel]()
  
  /**
   * The focused document. Can be None to represent no focus.
   */
  var current: Option[Document.Node.Name] = None
  
  /**
   * Custom Thy_Load to support internal LineBuffer representation
   */
  val thyLoad = new Thy_Load {
    override def read_header(name: Document.Node.Name): Thy_Header = {
      if (docs.isDefinedAt(name)) {
        Thy_Header.read(docs(name).buffer.mkString)        
      } else {        
	    val file = new java.io.File(name.node)
	    if (!file.exists || !file.isFile) error("No such file: " + quote(file.toString))
	    Thy_Header.read(file)
      }
    }
    
    override def append(dir: String, source_path: Path): String =
	{
	  val path = source_path.expand
	  if (path.is_absolute) Isabelle_System.platform_path(path)
	  else {
	    Path.explode(dir + "/" + source_path.implode).implode   
	  }
	}
  }
  
  val thyInfo = new Thy_Info(thyLoad)
  
  /**
   * The Isabelle session that is provided
   **/
  val session = new isabelle.Session(thyLoad)    

  session.phase_changed += { phase =>    
    js.ignore.setPhase(phase.toString)
    phase match {
      case Session.Ready =>
        js.ignore.setFiles(project.theories)
        js.ignore.setLogic(project.logic)
      case _ =>
    }
  }
  
  session.syslog_messages += { msg =>
    js.ignore.println(Pretty.str_of(msg.body))    
  }
  
  session.commands_changed += { change =>
    change.nodes.foreach { node =>
      delayedLoad(node)
      val snap = session.snapshot(node, Nil)
      val status = Protocol.node_status(snap.state, snap.version, snap.node)      
      js.ignore.status(
          node.toString, 
          status.unprocessed,
          status.running,
          status.finished,
          status.warned,
          status.failed)      
      for {
        doc <- docs.get(node)        
      } {        
        js.ignore.states(node.theory, MarkupTree.getStates(snap, doc.buffer.ranges))
        val cmds = snap.node.commands.map(_.id)
        doc.commands.keys.foreach { id =>
          if (!cmds.contains(id)) {
            doc.commands.remove(id)
            js.ignore.removeCommand(node.toString, id)
          }
        }
      }       
    }    
    change.commands.foreach(pushCommand)    
  }

  /**
   * Extract and compress command infos (See MarkupTree.scala) and send them to the client if 
   * necessary
   */
  def pushCommand(cmd: Command): Unit = {
    val node = cmd.node_name
    if (Some(node) != current) return 
    
    val snap = session.snapshot(node, Nil)
    val start = snap.node.command_start(cmd)
    val state = snap.state.command_state(snap.version, cmd)
    for (doc <- docs.get(node); start <- start) {
      val docStartLine = doc.buffer.line(start)
      var docEndLine = doc.buffer.line(start + cmd.length - 1)
      while (docEndLine >= 0 && !doc.buffer.lines(docEndLine).exists(c => c != ' ' && c != '\t'))
        docEndLine -= 1
      if (true) {//docStartLine >= doc.perspective._1 && docEndLine <= doc.perspective._2) {
	      val ranges = (docStartLine to docEndLine).map(doc.buffer.ranges.lift(_)).flatten.toVector
	      val cmdState = MarkupTree.getStates(snap, Vector((start, start + cmd.length - 1))).head
	      val tokens = MarkupTree.getTokens(snap, ranges).map {
	        _.map { token =>
	          val classes = token.info.map {
	            case x => x
	          }.distinct match {
	            case List("text") => "text"
	            case x            => x.filter(_ != "text").mkString(".")
	          }
	          val tooltip = MarkupTree.tooltip(snap, token.range)
	          Json.obj(
	            "value" -> doc.buffer.chars.slice(token.range.start, token.range.stop).mkString,
	            "type" -> classes,
	            "tooltip" -> tooltip
	          )
	        }
	      }
	      val json = Json.obj(
	        "id" -> cmd.id,
	        "version" -> doc.version,
	        "name" -> cmd.name,
	        "range" -> Json.obj(
	          "start" -> docStartLine,
	          "end" -> docEndLine),
	        "tokens" -> tokens,
	        "output" -> commandInfo(cmd),
	        "state" -> cmdState)
	      if (doc.commands.get(cmd.id) != Some(json))
	        doc.commands(cmd.id) = json
	        js.ignore.commandChanged(cmd.node_name.toString, json)
      }
    }
  }
  
  /**
   * Retrieve the Isabelle compatible Name of a Thy-File
   */
  def name(path: String) =
    Document.Node.Name(Path.explode(project.dir + path))  
   
  /**
   * Extract the header of a specific node
   */
  def node_header(name: isabelle.Document.Node.Name): isabelle.Document.Node_Header = Exn.capture {
    thyLoad.check_header(name,
      thyLoad.read_header(name))
  }
  
  js.convert = js.convert.orElse {    
    case t: Thy_Header => Json.obj(
      "name"     -> t.name,
      "imports"  -> t.imports,
      "keywords" -> t.keywords.map {
        case (a,Some((b,c))) => Json.obj("name" -> a)
        case (a,None) => Json.obj("name" -> a)
      },
      "uses" -> t.uses.map { 
        case (a,b) => Json.obj(
            "name" -> Json.toJson(a),
            "is" -> Json.toJson(b))            
      }
    )
  }
  
  /**
   * Convert command infos to HTML
   */
  def commandInfo(cmd: Command) = {
    val snap = session.snapshot(cmd.node_name, Nil)
    val start = snap.node.command_start(cmd).map(docs(cmd.node_name).buffer.line(_)).get
    val state = snap.state.command_state(snap.version, cmd)
    val filtered = state.results.map(_._2).filter(
	  {
	    case XML.Elem(Markup(Isabelle_Markup.TRACING, _), _) => false 
	    case _ => true
	  }).toList	
	val html_body =
      filtered.flatMap(div =>
	    Pretty.formatted(List(div), 0, Pretty.font_metric(null))
	      .map(t =>
	        XML.Elem(Markup(HTML.PRE, List((HTML.CLASS, Isabelle_Markup.MESSAGE))),
          HTML.spans(t, true))))    
    Pretty.string_of(state.results.values.toList)
  }
  
  /**
   * Load dependencies if necessary
   **/
  def delayedLoad(thy: Document.Node.Name) {    
    thyInfo.dependencies(List(thy)).foreach { case (name,header) =>      
      if (!docs.isDefinedAt(name)) try {                
        val text = Source.fromFile(name.dir + "/" + name.theory + ".thy").getLines.toTraversable // TODO        
        val doc = new RemoteDocumentModel()
        doc.buffer.lines.insertAll(0, text)
        session.init_node(name, node_header(name), Text.Perspective.full, doc.buffer.mkString)
        docs(name) = doc
        js.ignore.dependency(thy.toString, name.toString)
      } catch {
        case e: Throwable => 
          Logger.error(f"$thy could not be loaded")
          e.printStackTrace()
      }     
    }
  }

  val actions: PartialFunction[String, JsValue => Any] = {     
    case "getTheories" => json => project.theories
      
    case "open" => json => 
      val path = json.as[String]
      val node = name(path)
      
      val doc = this.docs.getOrElseUpdate(node, {
        val text = Source.fromFile(project.dir + path).getLines.toTraversable
        val doc = new RemoteDocumentModel     
        doc.buffer.lines.insertAll(0, text)
        session.init_node(node, node_header(node), Text.Perspective.full, doc.buffer.mkString)
        doc
      })
            
      doc.buffer.mkString
      
    case "new" => json =>
      val name = json.as[String]
      val path = name + ".thy"
      val realPath = project.dir + path
      val node = this.name(path)
      val doc = new RemoteDocumentModel
      doc.buffer.lines.insertAll(0,List(
        f"theory $name",
        "imports Main",
        "begin",
        "",
        "end"
      ))
      
      val out = scalax.io.Resource.fromFile(realPath)
      out.write(doc.buffer.mkString)      
      docs(node) = doc
      session.init_node(node, node_header(node), Text.Perspective.full, doc.buffer.mkString)
      js.ignore.addTheory(Theory(name,path))
      
    case "save" => json =>            
      if (json.as[Boolean]) {
        for ((path,doc) <- docs) {          
          println("save " + path)
          //val out = scalax.io.Resource.fromFile(path)
		  //out.write(doc.buffer.mkString)
        }
      } else {              
		for (current <- current; doc <- docs.get(current)) {		  
		  val out = scalax.io.Resource.fromFile(project.dir + current + ".thy")
		  out.truncate(0)
		  out.write(doc.buffer.mkString)
	    }
      }
      
    case "delete" => json =>
      println("delete " + json)
      val path = json.as[String]
      val node = name(path)
            
      docs.get(node) match {
        case None =>
          new java.io.File(project.dir + path).delete()
        case Some(doc) =>
          println("removed " + doc)
          docs.remove(node)          
          new java.io.File(project.dir + path).deleteOnExit()
          true
      }

    case "close" => json =>
      val nodeName = json.as[String] 
      
    case "edit" => json =>
      session.cancel_execution()
      val nodeName = name((json \ "path").as[String])
      val changes = (json \ "changes").as[Array[Change]]
      val version = (json \ "version").as[Int]
      docs.get(nodeName).map{ doc =>        
        val edits = changes.toList.flatMap(c => doc.change(c.from, c.to, c.text))
        session.edit_node(nodeName, node_header(nodeName), Text.Perspective.full, edits)
        doc.version = version        
        js.ignore.check(nodeName.toString, version, doc.buffer.mkString)
      }      
      
    case "changePerspective" => json =>
      val nodeName = name((json \ "path").as[String])
      val start = (json \ "start").as[Int]
      val end = (json \ "end").as[Int]
      for (doc <- docs.get(nodeName)) {
        doc.perspective = (start,end)               
      }      
      
    case "setCurrentDoc" => json =>
      current = Some(name(json.as[String]))
      
    case "cancel" => json =>
      session.cancel_execution()
      true
      
  }
   
  implicit def app = play.api.Play.current

  // We need to release the session in order to release all the resources attached 
  override def onClose() {
    session.stop()
    Cache.set(project.id,Cache.getOrElse(project.id,3600)(0) - 1,3600)        
  }
    
  Cache.set(project.id,Cache.getOrElse(project.id,3600)(0) + 1,3600)
  
  if (Cache.getOrElse(project.id)(0) > 1) {
    js.ignore.setPhase("already opened")
    js.ignore.println("failure: this session is already opened")
  }
  else {    
    session.start(List(project.logic))
  }
}