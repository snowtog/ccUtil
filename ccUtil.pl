#! ccperl -w
#########1#########2#########3#########4#########5#########6#########7#########8
#
# SCRIPT NAME	:	ccUtil.pl
# PURPOSE		:	This Perl script is a set of useful ClearCase utilities
#
my ${Author}	= "Chris Elliott" ;
my ${Date}		= "2008/09/30" ;
my ${Version}	= "v04.02" ;
#
#########1#########2#########3#########4#########5#########6#########7#########8

# Include additional Perl Modules
 BEGIN
	{
	  push (@INC,'\\\Rlchscmpfs07\CSRisk\Grm\Support\SCM\Perllib');
	}

use Cwd ;
use File::Basename ;
use File::Copy ;
use File::Copy::Recursive qw(fcopy rcopy dircopy fmove rmove dirmove) ;
use File::Find ;
use File::Path ;
use Getopt::Long ;
use IO::File ;
use strict ;
use warnings ;

#########1#########2#########3#########4#########5#########6#########7#########8
# Variable Declaration
#########1#########2#########3#########4#########5#########6#########7#########8
 # Filename
	my ${filename}  = basename($0) ;
	my ${programName}  = basename($0, ".pl") ;
 # Save start directory
	my ${startDir} = cwd ;
 # Site Variables
	my ${pvob} = "grdw" ;
 #Debug Level [0=None] [1=Show ClearTool Commands] [2=Exit Levels] [3=Report Subroutines]
	my ${debug} = 1 ;
# Signal Interrupts
	$SIG{INT} = 'sub_interrupt' ;	$SIG{QUIT} = 'sub_interrupt' ;
	$SIG{STOP} = 'sub_interrupt' ;	$SIG{ABRT} = 'sub_interrupt' ;
  # Environment Variables
	my ${user} = lc $ENV{'USERNAME'} ;
	my ${hostname} = $ENV{'COMPUTERNAME'} ;
	my ${logdir} = $ENV{'HOMESHARE'} ;
 # Date & Time
  # Initialize DateTime values
    my %dttime = ();
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  # Initialize DateTime number formats
	$dttime{year }  = sprintf "%04d",($year + 1900) ;	# four digits to specify the year
	$dttime{mon  }  = sprintf "%02d",($mon + 1) ;		# zeropad months
	$dttime{mday }  = sprintf "%02d",$mday ;			# zeropad day of the month
	$dttime{wday }  = sprintf "%02d",$wday + 1 ;		# zeropad day of week; sunday = 1;
	$dttime{yday }  = sprintf "%02d",$yday ;			# zeropad nth day of the year
	$dttime{hour }  = sprintf "%02d",$hour ;			# zeropad hour
	$dttime{min  }  = sprintf "%02d",$min; 				# zeropad minutes
	$dttime{sec  }  = sprintf "%02d",$sec ;				# zeropad seconds
	$dttime{isdst}  = $isdst;
 # TAR Archive
	my ${genRelScript} = "\\\\Rlchscmpfs07\\CSRisk\\GRM\\SUPPORT\\SCM\\grdwGenRel.pl" ;
	my ${tarCodeDir} ;
	my ${tarDir} ;
	my ${tarExe} = "\\\\Rlchscmpfs07\\CSRisk\\GRM\\SUPPORT\\SCM\\tar.exe" ;
	my ${tarfile} ;
	my ${tarInstallDir} ;
 # ClearCase Directories
	my ${slash} = "\\" ;
	my ${share_drive} = "C:" ;
	my ${share_dir} = ${slash}."Data".${slash}."ClearCase" ;
	my ${share} = "ClearCase";
	my ${unc_share} = ${slash}.${slash}.${hostname}.${slash}.${share} ;
	my ${viewroot} = ${share_drive}.${share_dir}.${slash}."ViewRoot" ;
	my ${viewstore} = ${unc_share}.${slash}."Views" ;
 # ClearCase Scalars
	my ${baseline} ;
	my ${blcmd} ;
	my ${blType} ;
	my ${ccPerl} = "ccperl.exe" ;
	my ${config_spec} ;
	my ${ct} = "cleartool" ;
	my ${elementType} ;
	my ${found_bls} ;
	my ${latest_bls} ;
	my ${logfile} = ${logdir}.${slash}.".".${programName}.".log" ;
	my ${myViews} ;
	my ${rec_bls} ;
	my ${usersView} ;
	my ${viewFilter} ;
	my ${viewType} ;
	my ${vob} ;
	my %{project} ;
	my @{baselines} ;
	my @{ccobject} ;
	my @{components} ;
	my @{found_blss} ;
	my @{latest_blss} ;
	my @{myViews} ;
	my @{rec_blss} ;
 # Working Scalars
	my ${answer} ;
	my ${cmd} ;
	my ${currentDirectory} ;
	my ${exitLevel} = 0 ;
	my ${noexit} ;
	my ${tag} ;
	my ${valid} ;

# File Handlers
	open (LOGFILE, ">>", ${logfile}) ;
	$| = 1 ;
	open (STDERR, ">>", ${logfile}) ;
	$| = 1 ;

# Get command line options
	my ${blankView} ;
	my ${commandLineMode} ;
	my ${createProject} ;
	my ${dynamicView} ;
	my ${force} ;
	my ${loadView} ;
	my ${menuMode} ;
	my ${obsoleteActivity} ;
	my ${obsoleteProject} ;
	my ${rebaseStage} ;
	my ${rebaseStream} ;
	my ${releaseStage} ;
	my ${removeAllViews} ;
	my ${removeProject} ;
	my ${removeView} ;
	my ${stageView} ;
	my ${streamView} ;
	my ${tarStream} ;
	my ${unlockProject} ;

	GetOptions (
				'blankView:s'			=>		\${blankView},
				'commandLineMode'		=>		\${commandLineMode},
				'menuMode'				=>		\${menuMode},
				'createProject:s'		=>		\${createProject},
				'debug=i'				=>		\${debug},
				'dynamicView:s'			=>		\${dynamicView},
				'force'					=>		\${force},
				'loadView:s'			=>		\${loadView},
				'obsoleteActivity:s'	=>		\${obsoleteActivity},
				'obsoleteProject:s'		=>		\${obsoleteProject},
				'rebaseStage:s'			=>		\${rebaseStage},
				'rebaseStream:s'		=>		\${rebaseStream},
				'releaseStage:s'		=>		\${releaseStage},
				'removeAllViews:s'		=>		\${removeAllViews},
				'removeProject:s'		=>		\${removeProject},
				'removeView:s'			=>		\${removeView},
				'stageView:s'			=>		\${stageView},
				'streamView:s'			=>		\${streamView},
				'tarStream:s'			=>		\${tarStream},
				'unlockProject:s'		=>		\${unlockProject},
			   );

#########1#########2#########3#########4#########5#########6#########7#########8
# Subroutine Declaration
#
# Each subroutine is topped & tailed with debug information for show entry
# and exit of the subroutine
#
#########1#########2#########3#########4#########5#########6#########7#########8

sub sub_debug()
{
   # Simple Debug subroutine - this could do more rather than just call the Log Message subroutine
	my ${msgType} = $_[0] ;
	my(${message}) = $_[1] ;
	&sub_logmsg(${msgType}, ${message}) ;
}

sub sub_usage()
{
	print "\nOptions:\n" ;

	print "\t[-dynamicView <streamname>]\t\tCreate Dynamic View\n" ;
	print "\t[-blankView <streamname>]\t\tCreate Snapshot View (No files)\n" ;
	print "\t[-loadView <streamname>]\t\tCreate Snapshot View (Loads latest baseline) \n" ;
	print "\t[-stageView <streamname>]\t\tCreate Snapshot View (Loads foundation baseline)\n" ;
	print "\t[-streamView <streamname>]\t\tCreate Snapshot View (Loads edited files)\n" ;
	print "\t[-releaseStage <streamname>]\t\tCreate Snapshot View and TAR files\n" ;
	print "\t[-createProject <projectname>]\t\tCreate Project\n" ;
	print "\t[-obsoleteActivity <projectname>]\tObsolete all projects activities\n" ;
	print "\t[-obsoleteProject <projectname>]\tObsolete an entire project\n" ;
	print "\t[-unlockProject <projectname>]\t\tUnlock an entire project\n" ;
	print "\t[-rebaseStage <streamname>]\t\tRebase Snapshot Stage View\n" ;
	print "\t[-rebaseStream <streamname>]\t\tRebase Snapshot Stream View\n" ;
	print "\t[-removeProject <projectname>]\t\tRemove un-used Project\n" ;
	print "\t[-removeView <viewname>]\t\tRemove view on this PC\n" ;
	print "\t[-removeAllViews]\t\t\tRemove all your views on this PC\n" ;

	print "\n\t[-CommandLineMode]\t\t\tAllows you to enter options\n" ;
	print "\n\t[-menuMode]\t\t\tClears the screen and pauses upon completion\n" ;
	print "\n\t[-debug 0|1|2|3]\t\t\tSets the level of debugging information (default = 1)\n" ;
	print "\t[-force]\t\t\t\tNo confirmation\n" ;
	
	print "\n\t<Return> = null answer\t\t\tExit Program\n" ;
}

sub sub_utilityDetails()
{
   # Subroutine to display Filename & Version details etc.
	(${debug} > 2) && &sub_debug(5, "-> sub_utilityDetails") ;
   # Clears the screen
	(defined(${menuMode})) && system(($^O eq 'MSWin32') ? 'cls' : 'clear') ;
	&sub_logmsg (3, "${programName} - Version: ${Version}") ;
	&sub_logmsg (3, "ClearCase Region Information: ${pvob}") ;
	(${debug} > 2) && &sub_debug(5, "<- sub_utilityDetails") ;
}

sub sub_interrupt()
{
	my(${signal}) = @_ ;
	(${debug} > 1) && &sub_debug(3, "-> sub_interrupt(${signal}") ;
	&sub_controlExit(4, "Interrupt Signal - $signal") ;
}

sub sub_logmsg()
{
	my(${msgType}) = $_[0] ;
	my(${message}) = $_[1] ;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	if    (${msgType} == 1) { print "\nCL: ${message}\n" ; }
	elsif (${msgType} == 2) { print "\nInput: ${message}" ; }
	elsif (${msgType} == 3) { print "\nInfo: ${message}\n" ; }
	elsif (${msgType} == 4) { print "\nError: ${message}\n" ; }
	elsif (${msgType} == 5) { print "\nSub: ${message}\n" ; }
	print (LOGFILE "\n$dttime{year}/$dttime{mon}/$dttime{mday} $dttime{hour}:$dttime{min}\t${message}") ;
}

sub sub_askQuestion()
{
	(${debug} > 2) && &sub_debug(5, "-> sub_askQuestion") ;
	my(${question}) = $_[0] ;
	my(${ccobject}) = $_[1] ;
	&sub_logmsg(2, "${question}") ;
   # Strip the answer of any line feeds and carriage returns
	chomp(${answer} = <STDIN>) ;
   # Exit if blank answer
	if (${answer} eq "")
		{
		  (${ccobject} eq "comment") ? ${answer} = "No Description provided" : &sub_controlExit(3, "-- ${programName} exiting --") ;
		}
   # List possible answers
	elsif (${answer} eq "?")
		{
		  &sub_listCCobject(${ccobject}) ;
		  &sub_askQuestion(${question}, ${ccobject}) ;
		}
	(${debug} > 2) && &sub_debug(5, "<- sub_askQuestion") ;
}

sub sub_runSystemCommand()
{
   # Subroutine to actually run the ClearCase Commands
	my(${debugLevel}) = @_ ;
	(${debug} > 2) && &sub_debug(5, "-> sub_runSystemCommand)") ;
	(${debug} > ${debugLevel}) && &sub_debug(1, ${cmd}) ;
   # Run the command and save the exit status
	system("${cmd}") ;
	${exitLevel} = $? ;
	(${debug} > 1) && &sub_debug(3, "Exit Level: ${exitLevel} - $!") ;
	(${debug} > 2) && &sub_debug(5, "<- sub_runSystemCommand)") ;
}

sub sub_controlExit()
{
   # Subroutine to control the exit and close the log file
	(${debug} > 2) && &sub_debug(5, "-> sub_controlExit") ;
	my(${msgType}) = $_[0] ;
	my(${message}) = $_[1] ;
	&sub_logmsg(${msgType}, ${message});
	(${debug} > 1) && &sub_debug(${msgType}, "Exit Level: ${exitLevel}") ;
	close LOGFILE ;
	if (defined ${menuMode})
		{
		  print "\n<Return> to close ..." ;
		  <STDIN> ;
		}
	exit ${exitLevel} ;
	(${debug} > 2) && &sub_debug(5, "<- sub_controlExit") ;
}

sub sub_snapshotView()
{
   # Subroutine to create a ClearCase Snapshot View - using option 'tmode'
   # tmode = transparent (as is) or strip-cr (remove carrige returns) to control how the files are got out of ClearCase ito the view
	my(${tmode}) = @_ ;
	(${debug} > 2) && &sub_debug(5, "-> sub_snapshotView(${tmode})") ;
   # Build the ClearCase Command
	${cmd} = ${ct}." mkview -tmode ".${tmode}." -ptime -snapshot -tag ".${project}{"view"}." -vws ".${viewstore}.${slash}.${project}{"view"}.".vws"." -stream stream:".${project}{"stream"}."@".${slash}.${pvob}." ".${usersView} ;
   # Build the ClearCase Command
	&sub_runSystemCommand(0) ;
	if (${exitLevel} > 0)
		{
		 # If failed to create the view it might be that the directory existed already and remove manaully
		  (-d ${usersView}) && &sub_controlExit(4, "Unable to create view, the directory <${usersView}> already exists.") || &sub_controlExit(4, "Unable to create view, please resolve manually.") ;
		}
	(${debug} > 2) && &sub_debug(5, "<- sub_snapshotView(${tmode})") ;
}

sub sub_dynamicView()
{
   # Subroutine to create a ClearCase Dynamic View
   # This does not work correctly yet and does not mount or start the view
	(${debug} > 2) && &sub_debug(5, "-> sub_dynamicView") ;
   # Build the ClearCase Command
	${cmd} = ${ct}." mkview -tag ".${project}{"view"}." -stream stream:".${project}{"stream"}."@".${slash}.${pvob}." ".${viewstore}.${slash}.${project}{"view"}.".vws" ;
   # Run the ClearCase Command
	&sub_runSystemCommand(0) ;
	(${debug} > 2) && &sub_debug(5, "<- sub_dynamicView") ;
}

sub sub_validateCCobject()
{
   # Subroutine to check that the entered ClearCase Stream or Project exists
	my(${ccobject}) = @_ ;
	(${debug} > 2) && &sub_debug(5, "-> sub_validateCCobject(${ccobject})") ;
   # Build the ClearCase Command
	${cmd} = ${ct}." ls".${ccobject}." -short ". ${project}{${ccobject}}."@".${slash}.${pvob} ;
   # Define what the users view should be
	${project}{"view"} = ${user}."_".${project}{"stream"} ;
	(${debug} > 0) && &sub_debug(1, ${cmd}) ;
   # Run the ClearCase Command saving the result in 'valid'
	${valid} = `${cmd}` ;
	${exitLevel} = $? ;
	(${debug} > 1) && &sub_debug(3, "Exit Level: ${exitLevel}") ;
   # Strip the result of any line feeds and carriage returns
	chomp(${valid}) ;
	(${debug} > 2) && &sub_debug(5, "<- sub_validateCCobject(${ccobject})") ;
}

sub sub_validateView()
{
   # Subroutine to check that a valid ClearCase View exists
	(${debug} > 2) && &sub_debug(5, "-> sub_validateView") ;
	${usersView} = ${viewroot}.${slash}.${project}{"view"} ;
   # Build the ClearCase Command
	${cmd} = ${ct}." lsview -long -properties -full ".${project}{"view"} ;
	(${debug} > 0) && &sub_debug(1, ${cmd}) ;
   # Run the ClearCase Command saving the result in 'valid'
	${valid} = `${cmd}` ;
	${exitLevel} = $? ;
	(${debug} > 1) && &sub_debug(3, "Exit Level: ${exitLevel}") ;
	(${debug} > 2) && &sub_debug(5, "<- sub_validateView") ;
}

sub sub_listCCobject()
{
   # Subroutine to list the possible streams, projects, views or baselines
	my(${ccobject}) = @_ ;
	(${debug} > 2) && &sub_debug(5, "-> sub_listCCobject(${ccobject})") ;
	if (${ccobject} eq "stream")
		{
		  print "\n" ;
		 # List the Streams
		  ${cmd} = ${ct}." ls".${ccobject}." -fmt \"%n\t \" "."-invob ".${slash}.${pvob} ;
		  &sub_runSystemCommand(0) ;
		}
	elsif (${ccobject} eq "view")
		{
		  print "\n" ;
		 # List the users views only
		  ${cmd} = ${ct}." ls".${ccobject}." -short ".${user}."*" ;
		  &sub_runSystemCommand(0) ;
		}
	elsif (${ccobject} eq "folder")
		{
		  print "\n" ;
		 # List the Project Folders
		  ${cmd} = ${ct}." ls".${ccobject}." -ancestor -depth 2 -invob ".${slash}.${pvob} ;
		  &sub_runSystemCommand(0) ;
		}
	elsif (${ccobject} eq "usage")
		{
		 # List the Usage Message
		  &sub_usage ;
		}		
   # List available baselines
	elsif (${ccobject} eq "bl")
		{
		  print "\n" ;
		 # For each of the current baselines
		  foreach (@{baselines})
			{
			 # Get the component name
			  &sub_baselineComponents($_) ;
			 # Build the ClearCase command to list available baselines for the component
			  ${cmd} = ${ct}." ls".${ccobject}." -short -component ".${project}{"component"}."@".${slash}.${pvob} ;
			 # Run the ClearCase command
			  &sub_runSystemCommand(0) ;
			}
		}
	print "\n" ;
	(${debug} > 2) && &sub_debug(5, "<- sub_listCCobject(${ccobject})") ;
}

sub sub_projectDetails()
{
   # Subroutine to collect all of a ClearCase Projects details
	(${debug} > 2) && &sub_debug(5, "-> sub_projectDetails") ;
   # Build the ClearCase Command to get the Integration stream
	${cmd} = ${ct}." lsproject -fmt \"%[istream]p\" ".${project}{"project"}."@".${slash}.${pvob} ;
	(${debug} > 0) && &sub_debug(1, ${cmd}) ;
	${project}{"stream"} = `${cmd}` ;
	${exitLevel} = $? ;
	(${debug} > 1) && &sub_debug(3, "Exit Level: ${exitLevel}") ;
   # Run the ClearCase Command again as the Branch Type and Stream name are the same
	${project}{"brtype"} = `${cmd}` ;
	${exitLevel} = $? ;
	(${debug} > 1) && &sub_debug(3, "Exit Level: ${exitLevel}") ;
   # Build and Run the ClearCase Command to get the Integration stream
	${cmd} = ${ct}." lsproject -fmt \"%[dstreams]p\" ".${project}{"project"}."@".${slash}.${pvob} ;
	(${debug} > 0) && &sub_debug(1, ${cmd}) ;
	${project}{"development"} = `${cmd}` ;
	${exitLevel} = $? ;
	(${debug} > 1) && &sub_debug(3, "Exit Level: ${exitLevel}") ;
   # Build and Run the ClearCase Command to get the Activities
	${cmd} = ${ct}." lsstream -fmt \"%[activities]p\" ".${project}{"stream"}."@".${slash}.${pvob} ;
	(${debug} > 0) && &sub_debug(1, ${cmd}) ;
	${project}{"activity"} = `${cmd}` ;
	${exitLevel} = $? ;
	(${debug} > 1) && &sub_debug(3, "Exit Level: ${exitLevel}") ;
	(${debug} > 2) && &sub_debug(5, "<- sub_projectDetails") ;
}

sub sub_createProject()
{
   # Subroutine to create a ClearCase Project
	(${debug} > 2) && &sub_debug(5, "-> sub_createProject") ;
   # Build and Run the ClearCase Command to create a project
	${cmd} = ${ct}." mkproject -comment \"".${project}{"comment"}."\" -modcomp ".${project}{"component"}." -in ".${project}{"folder"}."@".${slash}.${pvob}." ".${project}{"project"}."@".${slash}.${pvob} ;
	&sub_runSystemCommand(0) ;
	(${debug} > 2) && &sub_debug(5, "<- sub_createProject") ;
}

sub sub_createIntegrationStream()
{
   # Subroutine to create a ClearCase Integration Stream
	(${debug} > 2) && &sub_debug(5, "-> sub_createIntegrationStream") ;
   # Build and Run the ClearCase Command to create an integration stream
	${cmd} = ${ct}." mkstream -integration -comment \"".${project}{"comment"}." - LDN Development\" -in ".${project}{"project"}."@".${slash}.${pvob}." -target ".${project}{"target"}."@".${slash}.${pvob}." -baseline ".${project}{"bl"}." ".${project}{"stream"}."@".${slash}.${pvob} ;
	&sub_runSystemCommand(0) ;
	(${debug} > 2) && &sub_debug(5, "<- sub_createIntegrationStream") ;
}

sub sub_createDevelopmentStream()
{
   # Subroutine to create a ClearCase development Stream
	(${debug} > 2) && &sub_debug(5, "-> sub_createDevelopmentStream") ;
   # Build and Run the ClearCase Command to create an integration stream
	${cmd} = ${ct}." mkstream -comment \"".${project}{"comment"}." - IDC Development\" -in ".${project}{"stream"}."@".${slash}.${pvob}." -baseline ".${project}{"bl"}." ".${project}{"development"}."@".${slash}.${pvob} ;
	&sub_runSystemCommand(0) ;
	(${debug} > 2) && &sub_debug(5, "<- sub_createDevelopmentStream") ;
}

sub sub_unLock()
{
   # Subroutine to Unlock a ClearCase object - we need to unlock a stream and project in case it has been locked already
	my(${ccobject}) = @_ ;
	(${debug} > 2) && &sub_debug(5, "-> sub_unLock(${ccobject})") ;
   # Build the ClearCase Command
	${cmd} = ${ct}." unlock ".${ccobject}.":".${project}{${ccobject}}."@".${slash}.${pvob} ;
   # Run the ClearCase Command
	&sub_runSystemCommand(0) ;
	(${debug} > 2) && &sub_debug(5, "<- sub_unLock(${ccobject})") ;
}

sub sub_obsolete()
{
   # Subroutine to Lock Obsolete a ClearCase object
	my(${ccobject}) = @_ ;
	(${debug} > 2) && &sub_debug(5, "-> sub_obsolete(${ccobject})") ;
	@{ccobject} = split / /, ${project}{${ccobject}} ;
	if (${ccobject} eq "project")
		{
		 # Build the ClearCase Command to move the ClearCase Project into the Obsolete Folder
		  ${cmd} = ${ct}." chproject -to folder:Obsolete ".${project}{${ccobject}}."@".${slash}.${pvob} ;
		 # Run the ClearCase command
		  &sub_runSystemCommand(0) ;
		}
	foreach (@{ccobject})
	{
	 # Build and Run the ClearCase Command
	  ${cmd} = ${ct}." lock -obsolete -replace ".${ccobject}.":".$_."@".${slash}.${pvob} ;
	  &sub_runSystemCommand(0) ;
	}
	(${debug} > 2) && &sub_debug(5, "<- sub_obsolete(${ccobject})") ;
}

sub sub_removeObject()
{
   # Subroutine to Remove a ClearCase object
	my(${ccobject}) = $_[0] ;
	my(${projectItem}) = $_[1] ;
	(${debug} > 2) && &sub_debug(5, "-> sub_removeObject(${projectItem})") ;
	@{ccobject} = split / /, ${project}{${projectItem}} ;
	foreach (@{ccobject})
	{
	 # Build and Run the ClearCase Command
	  ${cmd} = ${ct}." rm".${ccobject}." -force ".$_."@".${slash}.${pvob} ;
	  &sub_runSystemCommand(0) ;
	}
	(${debug} > 2) && &sub_debug(5, "<- sub_removeObject(${ccobject})") ;
}

sub sub_removeView()
{
   # Subroutine to Remove a ClearCase View
	(${debug} > 2) && &sub_debug(5, "-> sub_removeView") ;
	chdir ${viewroot};
   # If a dynamic view, set -tag
   # When validating the view, we used the '-long -properties' commands to report the type of view
   # Now test to see if the word 'dynamic' occured in the validation
	if (${valid} =~ /dynamic/)
		{
		  ${tag} = "-tag " ;
		  ${viewType} = "Dynamic" ;
		}
	else
		{
		  ${tag} = " " ;
		  ${viewType} = "Snaphot" ;
		}
   # If option '-f' was used, then just remove the view without asking
	if (! defined ${force})
		{
		  &sub_askQuestion("Remove existing ${viewType} View: $project{\"view\"} ? [Y/N]: ") ;
		 # Only remove the view if the answer if Y - remember a blank answer will exit the program
		  if (${answer} =~ /\bY\b/i)
			{
			  ${cmd} = ${ct}." rmview ".${tag}.${project}{"view"} ;
			  &sub_runSystemCommand(0) ;
			}
		 # Normally if the view is not removed then we would exit, however we need to control this
		 # if we are removing all the views or just rebasing a stream
		  elsif (! defined ${noexit})
			{
			  &sub_controlExit(3, "-- ${programName} exiting --") ;
			}
		}
	else
		{
		 # Build the ClearCase Command to remove the view. The 'tag' controls is depends on if the view is dynamic or snapshot
		  ${cmd} = ${ct}." rmview ".${tag}.${project}{"view"} ;
		  &sub_runSystemCommand(0) ;
		}
	(${exitLevel} > 0) && &sub_controlExit(4, "Unable to completely remove view, please resolve manually.") ;
	(${debug} > 2) && &sub_debug(5, "<- sub_removeView") ;
}

sub sub_removeAllViews()
{
   # Subroutine to Remove all your ClearCase Views
	(${debug} > 2) && &sub_debug(5, "-> sub_rmAllViews") ;
   # Build the ClearCase Command to list all your views
	${cmd} = ${ct}." lsview -short ".${viewFilter} ;
	(${debug} > 0) && &sub_debug(1, ${cmd}) ;
   # Run the ClearCase command and save them into the variable 'myViews'
	${myViews} = `${cmd}` ;
	${exitLevel} = $? ;
	(${debug} > 1) && &sub_debug(3, "Exit Level: ${exitLevel}") ;
   # Set the flag not to exit if answer is no
	${noexit} = "rmAllViews" ;
   # Split the list of views into an array
	@{myViews} = split /\n/, ${myViews} ;
	foreach (@{myViews})
		{
		  ${project}{"view"} = $_ ;
		 # Double check the view again - a little over kill - and then remove
		  &sub_validateView ;
		  (${valid}) && &sub_removeView ;
		}
	(${debug} > 2) && &sub_debug(5, "<- sub_rmAllViews") ;
}

sub sub_rebase()
{
   # Subroutine to rebase a staging stream.
   # A baseline entered with a '-' will result in that baseline being removed.
	my(${blType}) = @_ ;
	(${debug} > 2) && &sub_debug(5, "-> sub_rebase(${blType})") ;
   # Get the list of baselines
	&sub_baselines(${blType}) ;
	&sub_logmsg (3, "Current Foundation Baselines: @{baselines}") ;
   # Ask for the new baseline name
	&sub_askQuestion("Enter new Baseline: ", "bl") ;
   # If the answer is 'update', then your view will be updated.
	(${answer} =~ /update/i) && return ;
	${baseline} = ${answer} ;
   # If the baseline starts with a '-', then remove the baseline
	if (${baseline} =~ /^-.*/)
		{
		  ${blcmd} = "-dbaseline" ;
		  ${baseline} =~ s/^-// ;
		}
	else
		{
		  ${blcmd} = "-baseline" ;
		}
   # Build and Run the ClearCase Command
	${cmd} = ${ct}." lsbl -short ".${baseline}."@".${slash}.${pvob} ;
	(${debug} > 0) && &sub_debug(1, ${cmd}) ;
	${valid} = `${cmd}` ;
	${exitLevel} = $? ;
	(${debug} > 1) && &sub_debug(3, "Exit Level: ${exitLevel}") ;
   # Check to see the baseline is valid
	if (${valid} =~ /${baseline}/)
		{
		 # Build and Run the ClearCase command to rebase and complete the stream
		  ${cmd} = ${ct}." rebase -complete -view ".${project}{"view"}." ".${blcmd}." ".${baseline}."@".${slash}.${pvob} ;
		  &sub_runSystemCommand(0) ;
		}
	else
		{
		  &sub_controlExit(4, "Baseline not recognised: ${baseline}") ;
		}
	(${debug} > 2) && &sub_debug(5, "<- sub_rebase") ;
}

sub sub_baselines()
{
   # Subroutine to list a stream baselines depending on the type requested - Foundation baselines
	my(${blType}) = @_ ;
	(${debug} > 2) && &sub_debug(5, "-> sub_baselines(${blType})") ;
   # Build and Run the ClearCase Command to list the streams baselines
	${cmd} = ${ct}." lsstream -fmt \"%[${blType}]p\" ".${project}{"stream"}."@".${slash}.${pvob} ;
	(${debug} > 0) && &sub_debug(1, ${cmd}) ;
   # Save the results into variable 'baseline'
	${baseline} = `${cmd}` ;
	${exitLevel} = $? ;
	(${debug} > 1) && &sub_debug(3, "Exit Level: ${exitLevel}") ;
   # Split the baselines into an array
	@{baselines} = split / /, ${baseline} ;
	(${debug} > 2) && &sub_debug(5, "<- sub_baselines(${blType})") ;
}

sub sub_baselineComponents()
{
   # Subroutine to list the baselines components
	my(${baseline}) = @_ ;
	(${debug} > 2) && &sub_debug(5, "-> sub_baselineComponents(${baseline})") ;
   # Build and run the ClearCase Command to list the baseline's component
	${cmd} = ${ct}." lsbl -fmt \"%[component]p\" ".${baseline}."@".${slash}.${pvob} ;
	(${debug} > 0) && &sub_debug(1, ${cmd}) ;
	${project}{"component"} = `${cmd}` ;
	${exitLevel} = $? ;
	(${debug} > 1) && &sub_debug(3, "Exit Level: ${exitLevel}") ;
   # Build and run the ClearCase Command to list the baseline's stream
	${cmd} = ${ct}." lsbl -fmt \"%[bl_stream]p\" ".${baseline}."@".${slash}.${pvob} ;
	(${debug} > 0) && &sub_debug(1, ${cmd}) ;
	${project}{"target"} = `${cmd}` ;
	${exitLevel} = $? ;
	(${debug} > 1) && &sub_debug(3, "Exit Level: ${exitLevel}") ;
	(${debug} > 2) && &sub_debug(5, "<- sub_baselineComponents(${baseline})") ;
}

sub sub_baselineElements()
{
   # Subroutine to find just the files identified by a Baseline and write them to the views 'config_spec' file
   # This currently ignores directories and link files
	my(${blType}) = @_ ;
	(${debug} > 2) && &sub_debug(5, "-> sub_baselineElements(${blType})") ;
   # Define the View Configuration Specification file
	${config_spec} = ${share_dir}.${slash}."Views".${slash}.${project}{"view"}.".vws".${slash}."config_spec" ;
   # Change directory to the Users View
    chdir ${usersView} ;
   # Get the list of baselines
	&sub_baselines(${blType}) ;
	foreach (@{baselines})
	{
	 # Get the baselines component
	  &sub_baselineComponents($_) ;
	 # Build and run the ClearCase command
	  ${cmd} = ${ct}." find ".${project}{"component"}." -type lf -nxname -element \"lbtype_sub(".$_.")\" -exec \"cmd /c echo load \"\"\\%CLEARCASE_PN%\"\"\" >> ".${config_spec} ;
	  &sub_runSystemCommand(0) ;
	}
	(${debug} > 2) && &sub_debug(5, "<- sub_baselineElements(${blType})") ;
}

sub sub_streamElements()
{
   # Subroutine to find just the files identified by a Stream and write them to the views 'config_spec' file
   # This currently ignores directories and link files
	my(${blType}) = @_ ;
	(${debug} > 2) && &sub_debug(5, "-> sub_streamElements(${blType})") ;
   # Define the View Configuration Specification file
	${config_spec} = ${share_dir}.${slash}."Views".${slash}.${project}{"view"}.".vws".${slash}."config_spec" ;
   # Change directory to the Users View
    chdir ${usersView} ;
   # Get the list of baselines
	&sub_baselines(${blType}) ;
	foreach (@{baselines})
	{
	 # Get the baselines component
	  &sub_baselineComponents($_) ;
	 # Build and run the ClearCase command
	  ${cmd} = ${ct}." find ".${project}{"component"}." -type lf -nxname -element \"brtype(".${project}{"stream"}.")\" -exec \"cmd /c echo load \"\"\\%CLEARCASE_PN%\"\"\" >> ".${config_spec} ;
	  &sub_runSystemCommand(0) ;
	}
	(${debug} > 2) && &sub_debug(5, "<- sub_streamElements(${blType})") ;
}

sub sub_loadComponents()
{
   # Subroutine to load all the conponents files by writing the component names to the view 'config_spec' file
	my(${blType}) = @_ ;
	(${debug} > 2) && &sub_debug(5, "-> sub_loadComponents(${blType})") ;
   # Define the View Configuration Specification file and Open
	${config_spec} = ${share_dir}.${slash}."Views".${slash}.${project}{"view"}.".vws".${slash}."config_spec" ;
	open (CONFIG_SPEC, ">>", ${config_spec}) ;
   # Get the list of baselines
	&sub_baselines(${blType}) ;
	foreach (@{baselines})
	{
	 # Get the baselines component and write it to the views 'config_spec' file
	  &sub_baselineComponents($_) ;
	  print (CONFIG_SPEC "load \\$project{component}\n") ;
	}
	close CONFIG_SPEC ;
	(${debug} > 2) && &sub_debug(5, "<- sub_loadComponents(${blType})") ;
}

sub sub_updateView()
{
   # Subroutine to Update a view using the ClearCase Command 'setcs'
	(${debug} > 2) && &sub_debug(5, "-> sub_updateView") ;
	&sub_logmsg (3, "Updating View: ${user}_$project{stream}") ;
	${cmd} = ${ct}." setcs -current" ;
	&sub_runSystemCommand(0) ;
	(${debug} > 2) && &sub_debug(5, "<- sub_updateView") ;
}

sub sub_createTar()
{
   # Subroutine to create an Archive TAR file
	my(${blType}) = @_ ;
	(${debug} > 2) && &sub_debug(5, "-> sub_createTar(${blType})") ;
   # Get the list of baselines for the view
	&sub_baselines(${blType}) ;
	chdir ${usersView} ;
   # Ask for the TAR filename
	&sub_askQuestion("Enter name for archive TAR file. (eg. CMR1234567): ") ;
   # Define the Archive TAR filename and check to see if it already exists
	${tarfile} = ${usersView}.${slash}.${answer}.".tar" ;
	if (-f ${tarfile} )
		{
		  &sub_askQuestion("Remove existing archive TAR file: \"${tarfile}\" ? [Y/N]: ") ;
		  (${answer} =~ /\bY\b/i) && (unlink(${tarfile}) || &sub_controlExit(4, "Can't remove file: $! -- ${programName} exiting --"))  || &sub_controlExit(3, "-- ${programName} exiting --") ;
		}
   # Create temporary working TAR Archive directories used to create the Archive TAR file
	${tarDir} = ${usersView}.${slash}.${answer} ;
	mkdir(${tarDir}) or &sub_controlExit(4, "Unable to create working directory <${tarDir}>: $!") ;
	${tarInstallDir} = ${tarDir}.${slash}."install" ;
	mkdir(${tarInstallDir}) or &sub_controlExit(4, "Unable to create working directory <${tarInstallDir}>: $!") ;
	${tarCodeDir} = ${tarDir}.${slash}."code" ;
	mkdir(${tarCodeDir}) or &sub_controlExit(4, "Unable to create working directory <${tarCodeDir}>: $!") ;
	foreach (@{baselines})
		{
		 # Get the baselines component
		  &sub_baselineComponents($_) ;
		 # Change directory into the component so as not to include the directory in the TAR
		  chdir "${usersView}${slash}$project{component}" ;
		  ${currentDirectory} = cwd ;
		 # Find the files and copy into the TAR working directories
		  find(\&sub_copyFiles, ${currentDirectory}) ;
		}
   # Build and run the TAR command
    chdir "${usersView}" ;
    ${cmd} = ${tarExe}." -cvf ".${tarfile}." ".${answer} ;
    &sub_runSystemCommand(0) ;
   # Check the TAR archive file was created
	(-f ${tarfile} ) && &sub_logmsg(3, "Archive file created: ${tarfile}") || &sub_logmsg(4, "Failed to create Archive file: ${tarfile}") ;
   # Remove temporary processing directories
	(${debug} < 2) && (rmtree(${tarDir}) or &sub_controlExit(4, "Can't remove working directory <${tarDir}>: $!")) ;
	(${debug} > 2) && &sub_debug(5, "<- sub_createTar(${blType})") ;
}

sub sub_copyFiles()
{
	(${debug} > 1) && &sub_debug(3, "-> sub_copyFiles") ;
	# Complete path to the file and split into directory and name
	 my ${absoluteComponentName} = $File::Find::name ;
	# Process the files only and disregard the directories
	 return unless -f ${absoluteComponentName} ;
	 my ${componentFile} = basename(${absoluteComponentName}) ;
	if (${absoluteComponentName} =~ /${currentDirectory}\/install/)
		{
	 	  ${componentFile} = ${tarInstallDir}.${slash}.${componentFile} ;
		  (${debug} > 2) && &sub_debug(3, "Coping install file: <${absoluteComponentName}> to <${componentFile}>") ;
		  copy(${absoluteComponentName}, ${componentFile}) or &sub_controlExit(4, "Can't copy file: $!") ;
		}
	elsif (${absoluteComponentName} =~ /${currentDirectory}\/code/)
		{
	 	  ${componentFile} = ${tarCodeDir}.${slash}.${componentFile} ;
		  (${debug} > 2) && &sub_debug(3, "Coping code file: <${absoluteComponentName}> to <${componentFile}>") ;
		  copy(${absoluteComponentName}, ${componentFile}) or &sub_controlExit(4, "Can't copy file: $!") ;
		}
	(${debug} > 1) && &sub_debug(5, "<- sub_copyFiles") ;
}

#########1#########2#########3#########4#########5#########6#########7#########8
#########1#########2#########3#########4#########5#########6#########7#########8
#
# Main processing block
#
#########1#########2#########3#########4#########5#########6#########7#########8
#########1#########2#########3#########4#########5#########6#########7#########8

# Check for Debug Mode
	if (${debug})
		{
		   (${debug} > 1) && &sub_debug(3, "Debug") ;
		}

# ClearCase Region Notification
	&sub_utilityDetails ;

# Check for Force Mode
	if (${force})
		{
		  (${debug} > 1) && &sub_debug(3, "Force") ;
		  &sub_logmsg(3, "Force in use");
		  ${force} = "YES" ;
		}

# Change directory to C:\Data\ClearCase\ViewRoot as UNC Paths are not supported
	chdir ${viewroot} ;

# Process the Commandline Options
 # Stage View Option
	if (defined ${stageView})
		{
		  (${debug} > 1) && &sub_debug(3, "Option: Stage View") ;
		  if (${stageView} eq "")
			{
			  &sub_askQuestion("Enter Staging Project Stream Name: ", "stream") ;
			  ${project}{"stream"} = ${answer} ;
			}
		  else
			{
			  ${project}{"stream"} = ${stageView} ;
			}
		  &sub_validateCCobject("stream") ;
		  (${valid} ne $project{"stream"}) && &sub_controlExit(4, "Invalid stream \"$project{\"stream\"}\"") ;
		  &sub_validateView ;
		  (${valid}) && &sub_removeView ;
		  &sub_snapshotView("transparent") ;
		  &sub_baselineElements("found_bls") ;
		  &sub_updateView ;
		}
 # Release Stage View Option
	elsif (defined ${releaseStage})
		{
		  (${debug} > 1) && &sub_debug(3, "Option: Release Stage View") ;
		  if (${releaseStage} eq "")
			{
			  &sub_askQuestion("Enter Staging Project Stream Name: ", "stream") ;
			  ${project}{"stream"} = ${answer} ;
			}
		  else
		    {
			  ${project}{"stream"} = ${releaseStage} ;
			}
		  &sub_validateCCobject("stream") ;
		  (${valid} ne $project{"stream"}) && &sub_controlExit(4, "Invalid stream \"$project{\"stream\"}\"") ;
		  &sub_validateView ;
		  ${noexit} = "release" ;
		  if (${valid})
		  	{
		  	  &sub_removeView ;
		  	  &sub_snapshotView("strip_cr") ;
		  	  &sub_baselineElements("found_bls") ;
		  	  &sub_updateView ;		 
		  	}
		  else
		  	{
		  	  &sub_snapshotView("strip_cr") ;
		  	  &sub_baselineElements("found_bls") ;
		  	  &sub_updateView ;
		  	}
		  &sub_createTar("found_bls") ;
		  (${exitLevel} > 0) && &sub_controlExit(4, "Error occured while creating the Release files") ;
		}
 # Stream View Option
	elsif (defined ${streamView})
		{
		  (${debug} > 1) && &sub_debug(3, "Option: Stream View") ;
		  if (${streamView} eq "")
			{
			  &sub_askQuestion("Enter Project Stream Name: ", "stream") ;
			  ${project}{"stream"} = ${answer} ;
			}
		  else
			{
			  ${project}{"stream"} = ${streamView} ;
			}
		  &sub_validateCCobject("stream") ;
		  (${valid} ne $project{"stream"}) && &sub_controlExit(4, "Invalid stream \"$project{\"stream\"}\"") ;
		  &sub_validateView ;
		  (${valid}) && &sub_removeView ;
		  &sub_snapshotView("transparent") ;
		  &sub_streamElements("found_bls") ;
		  &sub_updateView ;
		}
 # Loaded View Option
	elsif (defined ${loadView})
		{
		  (${debug} > 1) && &sub_debug(3, "Option: Loaded View") ;
		  if (${loadView} eq "")
			{
			  &sub_askQuestion("Enter Project Stream Name: ", "stream") ;
			  ${project}{"stream"} = ${answer} ;
			}
		  else
			{
			  ${project}{"stream"} = ${loadView} ;
			}
		  &sub_validateCCobject("stream") ;
		  (${valid} ne $project{"stream"}) && &sub_controlExit(4, "Invalid stream \"$project{\"stream\"}\"") ;
		  &sub_validateView ;
		  (${valid}) && &sub_removeView ;
		  &sub_snapshotView("transparent") ;
		  &sub_loadComponents("latest_bls") ;
		  &sub_updateView ;
		}
 # Dynamic View Option
	elsif (defined ${dynamicView})
		{
		  (${debug} > 1) && &sub_debug(3, "Option: Dynamic View") ;
		  if (${dynamicView} eq "")
			{
			  &sub_askQuestion("Enter Project Stream Name: ", "stream") ;
			  ${project}{"stream"} = ${answer} ;
			}
		  else
			{
			  ${project}{"stream"} = ${dynamicView} ;
			}
		  &sub_validateCCobject("stream") ;
		  (${valid} ne $project{"stream"}) && &sub_controlExit(4, "Invalid stream \"$project{\"stream\"}\"") ;
		  &sub_validateView ;
		  (${valid}) && &sub_removeView ;
		  &sub_dynamicView ;
		}
 # Blank Snapshot View Option
	elsif (defined ${blankView})
		{
		  (${debug} > 1) && &sub_debug(3, "Option: Blank View") ;
		  if (${blankView} eq "")
			{
			  &sub_askQuestion("Enter Project Stream Name: ", "stream") ;
			  ${project}{"stream"} = ${answer} ;
			}
		  else
			{
			  ${project}{"stream"} = ${blankView} ;
			}
		  &sub_validateCCobject("stream") ;
		  (${valid} ne $project{"stream"}) && &sub_controlExit(4, "Invalid stream \"$project{\"stream\"}\"") ;
		  &sub_validateView ;
		  (${valid}) && &sub_removeView ;
		  &sub_snapshotView("transparent") ;
		}
 # Remove single View Option
	elsif (defined ${removeView})
		{
		  (${debug} > 1) && &sub_debug(3, "Option: Remove View") ;
		  if (${removeView} eq "")
			{
			  &sub_askQuestion("Enter View Name to Remove: ", "view") ;
			  ${project}{"view"} = ${answer} ;
			}
		  else
			{
			  ${project}{"view"} = ${removeView} ;
			}
		  &sub_validateView ;
		   (${valid}) ? &sub_removeView : &sub_controlExit(4, "Invalid view name: <$project{view}>") ;
		}
 # Remove All Your Views Option
	elsif (defined ${removeAllViews})
		{
		  (${debug} > 1) && &sub_debug(3, "Option: Remove All My Views") ;
		  (${removeAllViews} eq "") ? (${viewFilter} = ${user}."*") : (${viewFilter} = ${removeAllViews}) ;
		  &sub_removeAllViews ;
		}
 # Remove Un-used Project
	elsif (defined ${removeProject})
		{
		  (${debug} > 1) && &sub_debug(3, "Option: Remove Project") ;
		  if (${removeProject} eq "")
			{
			  &sub_askQuestion("Enter Project to remove: ", "project") ;
			  ${project}{"project"} = ${answer} ;
			}
		  else
			{
			  ${project}{"project"} = ${removeProject} ;
			}
		  &sub_validateCCobject("project") ;
		  (${valid} ne $project{"project"}) && &sub_controlExit(4, "Invalid project \"$project{\"project\"}\"") ;
		  &sub_projectDetails(${project}{"project"}) ;
		  ( ${project}{"development"} ne "" ) ? &sub_removeObject("stream", "development") : &sub_controlExit(4, "Stream in use \"$project{\"stream\"}\"") ;
		  ( ${project}{"stream"} ne "" ) ? &sub_removeObject("stream", "stream") : &sub_controlExit(4, "Stream in use \"$project{\"stream\"}\"") ;
		  ( ${project}{"project"} ne "" ) ? &sub_removeObject("project", "project") : &sub_controlExit(4, "Project in use \"$project{\"project\"}\"") ;
		}
 # Rebase Stage View Option
	elsif (defined ${rebaseStage})
		{
		  (${debug} > 1) && &sub_debug(3, "Option: Rebase View") ;
		  if (${rebaseStage} eq "")
			{
			  &sub_askQuestion("Enter Project Stream Name to Rebase: ", "stream") ;
			  ${project}{"stream"} = ${answer} ;
			}
		  else
			{
			  ${project}{"stream"} = ${rebaseStage} ;
			}
		  &sub_validateCCobject("stream") ;
		  (${valid} ne $project{"stream"}) && &sub_controlExit(4, "Invalid stream \"$project{\"stream\"}\"") ;
		  &sub_validateView ;
		  ${noexit} = "rebase" ;
		  (${valid}) ? &sub_removeView : &sub_snapshotView("transparent") ;
		  while ( ${answer} !~ /update/i )
			{
			  &sub_rebase("found_bls") ;
			}
		  &sub_baselineElements("found_bls") ;
		  &sub_updateView ;
		}
# Rebase Stream View Option
	elsif (defined ${rebaseStream})
		{
		  (${debug} > 1) && &sub_debug(3, "Option: Rebase Stream View") ;
		  if (${rebaseStream} eq "")
			{
			  &sub_askQuestion("Enter Project Stream Name to Rebase: ", "stream") ;
			  ${project}{"stream"} = ${answer} ;
			}
		  else
			{
			  ${project}{"stream"} = ${rebaseStream} ;
			}
		  &sub_validateCCobject("stream") ;
		  (${valid} ne $project{"stream"}) && &sub_controlExit(4, "Invalid stream \"$project{\"stream\"}\"") ;
		  &sub_validateView ;
		  ${noexit} = "rebase" ;
		  if (${valid})
		  	{
		  	  &sub_removeView
		  	}
		  else
		  	{
		  	  &sub_snapshotView("transparent") ;
		  	  &sub_streamElements("found_bls") ;
		  	  &sub_updateView ;
		  	}
		  while ( ${answer} !~ /update/i )
			{
			  &sub_rebase("found_bls") ;
			}
		  &sub_baselineElements("found_bls") ;
		  &sub_updateView ;
		}
 # Lock Obsolete Streams Activities Option
	elsif (defined ${obsoleteActivity})
		{
		  (${debug} > 1) && &sub_debug(3, "Option: Obsolete Activity") ;
		  if (${obsoleteActivity} eq "")
			{
			  &sub_askQuestion("Enter Project containing Activities: ", "project") ;
			  ${project}{"project"} = ${answer} ;
			}
		  else
			{
			  ${project}{"stream"} = ${obsoleteActivity} ;
			}
		  &sub_validateCCobject("project") ;
		  (${valid} ne $project{"project"}) && &sub_controlExit(4, "Invalid project \"$project{\"project\"}\"") ;
		  &sub_projectDetails(${project}{"project"}) ;
		  &sub_obsolete("activity") ;
		}
 # Lock Obsolete entire Project Option
	elsif (defined ${obsoleteProject})
		{
		  (${debug} > 1) && &sub_debug(3, "Option: Obsolete Project") ;
		  if (${obsoleteProject} eq "")
			{
			  &sub_askQuestion("Enter Project Name to Obsolete: ", "project") ;
			  ${project}{"project"} = ${answer} ;
			}
		  else
			{
			  ${project}{"project"} = ${obsoleteProject} ;
			}
		  &sub_validateCCobject("project") ;
		  (${valid} ne $project{"project"}) && &sub_controlExit(4, "Invalid project \"$project{\"project\"}\"") ;
		  &sub_projectDetails(${project}{"project"}) ;
		  &sub_unLock("project") ;
		  &sub_unLock("stream") ;
		  &sub_obsolete("activity") ;
		  &sub_obsolete("brtype") ;
		  &sub_obsolete("stream") ;
		  &sub_obsolete("project") ;
		}
 # Unlock entire Project Option
	elsif (defined ${unlockProject})
		{
		  (${debug} > 1) && &sub_debug(3, "Option: Unlock Project") ;
		  if (${unlockProject} eq "")
			{
			  &sub_askQuestion("Enter Project Name to Unlock: ", "project") ;
			  ${project}{"project"} = ${answer} ;
			}
		  else
			{
			  ${project}{"project"} = ${unlockProject} ;
			}
		  &sub_validateCCobject("project") ;
		  (${valid} ne $project{"project"}) && &sub_controlExit(4, "Invalid project \"$project{\"project\"}\"") ;
		  &sub_projectDetails(${project}{"project"}) ;
		  &sub_unLock("project") ;
		  &sub_unLock("stream") ;
		  &sub_unLock("brtype") ;
		}
# Create a new Project Option
	elsif (defined ${createProject})
		{
		  (${debug} > 1) && &sub_debug(3, "Option: Create Project") ;
		  if (${createProject} eq "")
			{
			  &sub_askQuestion("Enter Project Name: ", "project") ;
			  ${project}{"project"} = ${answer} ;
			}
		  else
			{
			  ${project}{"project"} = ${createProject} ;
			}
		  &sub_validateCCobject("project") ;
		  (${valid} eq $project{"project"}) && &sub_controlExit(4, "Project already exists: \"$project{\"project\"}\"") ;
		  ${project}{"stream"} = ${project}{"project"}."_ldn_int" ;
		  &sub_askQuestion("Enter Project Description: ", "comment") ;
		  ${project}{"comment"} = ${answer} ;		  
		  &sub_askQuestion("Enter Foundation Baseline: ", "bl") ;
		  ${project}{"bl"} = ${answer} ;
		  &sub_validateCCobject("bl") ;
		  (${valid} ne $project{"bl"}) && &sub_controlExit(4, "Invalid foundation baseline \"$project{\"bl\"}\"") ;
		  &sub_askQuestion("Enter Project Folder: ", "folder") ;
		  ${project}{"folder"} = ${answer} ;
		  &sub_validateCCobject("folder") ;
		  (${valid} ne $project{"folder"}) && &sub_controlExit(4, "Invalid project folder \"$project{\"folder\"}\"") ;
		  &sub_baselineComponents(${project}{"bl"}) ;
		  &sub_createProject ;
		  &sub_createIntegrationStream ;
		  ${project}{"development"} = ${project}{"project"}."_idc_int" ;
		  &sub_askQuestion("Create development stream: $project{\"development\"} ? [Y/N]: ") ;
		  (${answer} =~ /\bY\b/i) &&  &sub_createDevelopmentStream ;
		}
 # Command Line Mode
	elsif (defined ${commandLineMode})
		{
		  (${debug} > 1) && &sub_debug(3, "Option: Command Line Mode") ; 
		  while (${commandLineMode})
		  	{
		  	  &sub_askQuestion("Enter ccUtil Option: ", "usage") ;
		   	  ${cmd} = ${filename}." ".${answer} ;
		   	  &sub_runSystemCommand(0) ;
		  	}
		 }
 # Option not recognised.
	else
		{
		  (${debug} > 1) && &sub_debug(3, "Invalid Option") ;
		  &sub_usage ;
		}

# Clean and Close
	&sub_controlExit(3, "-- ${programName} completed --") ;
