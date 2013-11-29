<%@page import="db.DBConnection"%>
<%@page import="sql.*"%>
<%@page import="java.util.*"%>
<%@page import="helper.*"%>
<jsp:useBean id="dbaccess" class="db.DBAccess" scope="session" />
<jsp:useBean id="usersession" class="helper.UserSession" scope="session" />
<jsp:useBean id="ldap" class="ldap.LDAPAuthenticate" scope="session" />
<!doctype html>
<html lang="en">
<head>
	<meta http-equiv="Content-Type" content="text/html" charset="utf-8" />
	<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>Add Meeting Attendee</title>
	<link rel="icon" href="http://www.cssreset.com/favicon.png">
	<link rel="stylesheet" type="text/css" media="all" href="css/fonts.css">
	<link rel="stylesheet" type="text/css" media="all" href="css/themes/base/style.css">
	<link rel="stylesheet" type="text/css" media="all" href="css/themes/base/jquery.ui.core.css">
	<link rel="stylesheet" type="text/css" media="all" href="css/themes/base/jquery.ui.theme.css">
	<link rel="stylesheet" type="text/css" media="all" href="css/themes/base/jquery.ui.selectmenu.css">
	<script type="text/javascript" src="http://code.jquery.com/jquery-1.9.1.js"></script>
	<script type="text/javascript" src="js/modernizr.custom.79639.js"></script>
	<script type="text/javascript" src="js/ui/jquery.ui.core.js"></script>
	<script type="text/javascript" src="js/ui/jquery.ui.widget.js"></script>
	<script type="text/javascript" src="js/ui/jquery.ui.position.js"></script>
	<script type="text/javascript" src="js/ui/jquery.ui.selectmenu.js"></script>
	<script type="text/javascript" src="js/ui/jquery.ui.stepper.js"></script>
	<script type="text/javascript" src="js/ui/jquery.ui.dataTable.js"></script>
<%@ include file="search.jsp" %>
<%
    //Start page validation
    String userId = usersession.getUserId();
    if (userId.equals("")) {
        response.sendRedirect("index.jsp?message=Please log in");
        return;
    }
    String message = request.getParameter("message");
    String errMessage = request.getParameter("errMessage");
    if (message == null || message == "null") {
        message="";
    }
    if (errMessage == null) {
    	errMessage="";
    }
    String m_id = request.getParameter("m_id");
    String ms_id = request.getParameter("ms_id");
    if (m_id==null || ms_id==null) {
        response.sendRedirect("calendar.jsp?errMessage=Please do not mess with the URL");
        return;
    }
    m_id = Validation.prepare(m_id);
    ms_id = Validation.prepare(ms_id);
    if (!(Validation.checkMId(m_id) && Validation.checkMsId(ms_id))) {
        response.sendRedirect("calendar.jsp?message=" + Validation.getErrMsg());
        return;
    }
    User user = new User(dbaccess);
    Meeting meeting = new Meeting(dbaccess);
    MyBoolean myBool = new MyBoolean();    
    if (!meeting.isMeeting(myBool, ms_id, m_id)) {
        message = "Could not verify meeting status (ms_id: " + ms_id + ", m_id: " + m_id + ")" + meeting.getErrMsg("AA01");
        response.sendRedirect("logout.jsp?message=" + message);
        return;   
    }
    if (!myBool.get_value()) {
        response.sendRedirect("calendar.jsp?message=You do not permission to access that page");
        return;
    }
    if (!user.isMeetingCreator(myBool, ms_id, userId)) {
        message = "Could not verify meeting status (ms_id: " + ms_id + ", m_id: " + m_id + ")" + user.getErrMsg("AA02");
        response.sendRedirect("logout.jsp?message=" + message);
        return;   
    }
    if (!myBool.get_value()) {
        response.sendRedirect("calendar.jsp?message=You do not permission to access that page");
        return;
    }
    // End page validation
    
    // Start User Search
    int i = 0;
    boolean searchSucess = false;
    String bu_id = request.getParameter("searchBox");
    if (bu_id!=null) {
        bu_id = Validation.prepare(bu_id);
        if (!(Validation.checkBuId(bu_id))) {
            message = Validation.getErrMsg();
        } else {
            if (!user.isMeetingAttendee(myBool, ms_id, bu_id)) {
                message = "Could not verify meeting status (ms_id: " + ms_id + ", m_id: " + m_id + ")" + user.getErrMsg("AA03");
                response.sendRedirect("logout.jsp?message=" + message);
                return;   
            }
            // User already added
            if (myBool.get_value()) {
                message = "User already added";
            } else {
                if (!user.isUser(myBool, bu_id)) {
                    message = user.getErrMsg("AA04");
                    response.sendRedirect("logout.jsp?message=" + message);
                    return;   
                }
                // User already in Database
                if (myBool.get_value()) {   
                    searchSucess = true;
                } else {
                    // Found userId in LDAP
                    if (findUser(dbaccess, ldap, bu_id)) {
                        searchSucess = true;
                    } else {
                        message = "User Not Found";
                    }
                }
            }
        }
    }
    // End User Search
    
    if (searchSucess) {
        if (!meeting.createMeetingAttendee(bu_id, ms_id, false)) {
            message = meeting.getErrMsg("AA05");
            response.sendRedirect("logout.jsp?message=" + message);
            return;   
        } else {
            message = bu_id + " added to meeting attendee list";
        }
    } else {
        String mod = request.getParameter("mod");
        String remove = request.getParameter("remove");
        if (mod != null) {
            mod = Validation.prepare(mod);
            if (!(Validation.checkBuId(mod))) {
                message = Validation.getErrMsg();
            } else {
                if (!meeting.setMeetingAttendeeIsMod(mod, ms_id)) {
                    message = meeting.getErrMsg("AA06");
                    response.sendRedirect("logout.jsp?message=" + message);
                    return;   
                }
            }  
        } else if (remove != null) {
            remove = Validation.prepare(remove);
            if (!(Validation.checkBuId(remove))) {
                message = Validation.getErrMsg();
            } else {
                if (!user.isMeetingAttendee(myBool, ms_id, remove)) {
                    message = user.getErrMsg("AA07");
                    response.sendRedirect("logout.jsp?message=" + message);
                    return;   
                } else {
                    if (myBool.get_value()) { 
                        if (!meeting.removeMeetingAttendee(remove, ms_id)) {
                            message = meeting.getErrMsg("AA08");
                            response.sendRedirect("logout.jsp?message=" + message);
                            return;   
                        } else {
                            message = remove + " was removed from attendee list";
                        }                         
                    } else {
                        message = "User to be removed not in attendee list";   
                    }
                }              
            }  
        }
    }
    
    ArrayList<ArrayList<String>> eventAttendee = new ArrayList<ArrayList<String>>();
    if (!meeting.getMeetingAttendee(eventAttendee, ms_id)) {
        message = meeting.getErrMsg("AA09");
        response.sendRedirect("logout.jsp?message=" + message);
        return;   
    }                                
%>

<script type="text/javascript">
/* TABLE */
$(screen).ready(function() {

    $('#tbAttendee').dataTable({"sPaginationType": "full_numbers"});
    $('#tbAttendee').dataTable({"aoColumnDefs": [{ "bSortable": false, "aTargets":[5]}], "bRetrieve": true, "bDestroy": true});
    $.fn.dataTableExt.sErrMode = 'throw';
    $('.dataTables_filter input').attr("placeholder", "Filter entries");
    $(".remove").click(function(){
        return window.confirm("Remove this person from list?");
    });   
});
/* SELECT BOX */
$(function(){
    $('select').selectmenu();
});
</script>
</head>

<body>
<div id="page">
    <jsp:include page="header.jsp"/>
    <jsp:include page="menu.jsp"/>
    <section>
        <header> 
            <!-- BREADCRUMB -->
            <p><a href="calendar.jsp" tabindex="13">home</a> � 
                <a href="view_event.jsp?ms_id=<%= ms_id %>&m_id=<%= m_id %>" tabindex="14">view_event</a> � 
                <a href="add_attendee.jsp?ms_id=<%= ms_id %>&m_id=<%= m_id %>" tabindex="15">add_attendee</a></p>
            <!-- PAGE NAME -->
            <h1>Add Meeting Attendee</h1>
            <br />
            <!-- WARNING MESSAGES -->
            <div class="warningMessage"><%=message %></div>
            <div class="errorMessage"><%=errMessage %></div>
        </header>
        <form name="addAttendee" method="get" action="add_attendee.jsp">
            <article>
                <header>
                  <h2>Add attendee</h2>
                  <img class="expandContent" width="9" height="6" src="images/arrowDown.svg" title="Click here to collapse/expand content" alt="Arrow"/>
                </header>
                <div class="content">
                    <fieldset>
                        <div class="component">
                            <input type="hidden" name="ms_id" id="ms_id" value="<%= ms_id %>">
                            <input type="hidden" name="m_id" id="m_id" value="<%= m_id %>">  
                            <label for="searchBoxAddAttendee" class="label">Search User:</label>
                              <input type="text" name="searchBox" id="searchBox" class="searchBox" tabindex="37" title="Search user">
                              <button type="submit" name="search" class="search" tabindex="38" title="Search user"></button><div id="responseDiv"></div>
                        </div>
                    </fieldset>
                </div>
            </article>
            <article>
                <header id="expandAttendee">
                    <h2>Meeting Attendee List</h2>
                    <img class="expandContent" width="9" height="6" src="images/arrowDown.svg" title="Click here to collapse/expand content"/>
                </header>
                <div class="content">
                    <fieldset>
                        <div id="currentEventDiv" class="tableComponent">
                            <table id="tbAttendee" border="0" cellpadding="0" cellspacing="0">
                                <thead>
                                    <tr>
                                        <th class="firstColumn" tabindex="16">Id<span></span></th>
                                        <th>Nick Name<span></span></th>
                                        <th>Moderator<span></span></th>
                                        <th title="Action" class="icons" align="center">Modify</th>
                                        <th width="65" title="Remove" class="icons" align="center">Remove</th>
                                    </tr>
                                </thead>
                                <tbody>
                                <% for (i=0; i<eventAttendee.size(); i++) { %>
                                    <tr>
                                        <td class="row"><%= eventAttendee.get(i).get(0) %></td>
                                        <td><%= eventAttendee.get(i).get(3) %></td>
                                        <td><%= eventAttendee.get(i).get(2).equals("1") ? "Yes" : "" %></td>
                                        <td class="icons" align="center">
                                            <a href="add_attendee.jsp?ms_id=<%= ms_id %>&m_id=<%= m_id %>&mod=<%= eventAttendee.get(i).get(0) %>" class="modify">
                                            <img src="images/iconPlaceholder.svg" width="17" height="17" title="Modify Mod Status" alt="Modify"/>
                                        </a></td>
                                        <td class="icons" align="center">
                                            <a href="add_attendee.jsp?ms_id=<%= ms_id %>&m_id=<%= m_id %>&remove=<%= eventAttendee.get(i).get(0) %>" class="remove">
                                            <img src="images/iconPlaceholder.svg" width="17" height="17" title="Remove user" alt="Remove"/>
                                        </a></td>
                                    </tr>
                                <% } %>
                                </tbody>
                            </table>
                        </div>
                    </fieldset>
                </div>
            </article>
            <br /><hr /><br />
            <article>
                <div class="component">
                    <div class="buttons">
                        <button type="button" name="button" id="returnButton"  class="button" title="Click here to return to event page" 
                            onclick="window.location.href='view_event.jsp?ms_id=<%= ms_id %>&m_id=<%= m_id %>'">Return to Event Page</button>
                      </div>
                   </div>
            </article>
        </form>
    </section>
    <jsp:include page="footer.jsp"/>
</div>
</body>
</html>