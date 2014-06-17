#! ccperl -w
############################################################################
#
# SCRIPT NAME	: 	ccUtil.pl
# PURPOSE		: 	This Perl script is a set of useful ClearCase utilities 
#
	my ${Author}	= "Chris Elliott" ;
	my ${Date}		= "2008/08/13" ;
 	my ${Version}	= "1.9" ;
#
############################################################################

use strict ;  # Enforce some good programming rules
use warnings ;
use Cwd ;
use Getopt::Long ;
use File::Copy ;
use File::Basename ;

# Variable Declaration
 # Site Variables
 	my ${pvob} = "grdw" ;
 #Debug Level [0=None] [1=Show ClearTool Commands] [2=Report Subroutine Names]
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
    $dttime{year }  = sprintf "%04d",($year + 1900);  # four digits to specify the year
    $dttime{mon  }  = sprintf "%02d",($mon + 1);      # zeropad months
    $dttime{mday }  = sprintf "%02d",$mday;           # zeropad day of the month
    $dttime{wday }  = sprintf "%02d",$wday + 1;       # zeropad day of week; sunday = 1;
    $dttime{yday }  = sprintf "%02d",$yday;           # zeropad nth day of the year
    $dttime{hour }  = sprintf "%02d",$hour;           # zeropad hour
    $dttime{min  }  = sprintf "%02d",$min;            # zeropad minutes
    $dttime{sec  }  = sprintf "%02d",$sec;            # zeropad seconds
    $dttime{isdst}  = $isdst;
 # ClearCase Directories
	my ${ct} = "cleartool" ;
	my ${slash} = "\\" ;
	my ${share_drive} = "C:" ;
	my ${share_dir} = ${slash} . "Data". ${slash} . "ClearCase" ;
	my ${share} = "ClearCase";
	my ${unc_share} = ${slash} . ${slash} . ${hostname} . ${slash} . ${share} ;
	my ${viewroot} = ${share_drive} . ${share_dir} . ${slash} . "ViewRoot" ;
	my ${viewstore} =	${unc_share} . ${slash} . "Views" ;
	my ${ccutillog} = ${logdir} . ${slash} . ".ccutil.log" ;
 # ClearCase Scalars
	my ${baseline} ;
	my ${blcmd} ;
	my ${blType} ;
	my ${component} ;
	my ${config_spec} ;
	my ${elementType} ;
	my ${found_bls} ;
	my ${latest_bls} ;
	my ${myViews} ;
	my ${rec_bls} ;
	my ${view} ;
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
	my ${exitlevel} = 0;
	my ${noexit} ;
	my ${tag} ;
	my ${valid} ;

# File Handlers
 	open (LOGFILE, ">>", ${ccutillog}) ;

# Get command line options
	my ${emptyView} ;
	my ${force} ;
	my ${stageView} ;
	my ${streamView} ;
	my ${snapView} ;
	my ${dynamicView} ;
	my ${removeView} ;
	my ${rmAllViews} ;
	my ${rebaseStage} ;
	my ${obsoleteActivity} ;
	my ${obsoleteProject} ;
	
	GetOptions (
				'debug=i'				=>		\${debug},
				'force'					=>		\${force},
				'dynamicView:s'			=>		\${dynamicView},
				'emptyView:s'			=>		\${emptyView},
				'obsoleteActivity:s'	=>		\${obsoleteActivity},
				'obsoleteProject:s'		=>		\${obsoleteProject},
				'rebaseStage'			=>		\${rebaseStage},
				'removeView:s'			=>		\${removeView},
				'rmAllViews'			=>		\${rmAllViews},
				'snapView:s'			=>		\${snapView},
				'stageView:s'			=>		\${stageView},
				'streamView:s'			=>		\${streamView},
			  );
			
# Subroutine Declaration

sub sub_debug()
{
	my ${msgType} = $_[0] ;
	my(${message}) = $_[1] ;
	&sub_logmsg(${msgType}, ${message}) ;
}

sub sub_usage()
{
	print "\nOptions:\n" ;
	print "\t[-debug 0|1|2]\t\t\t\tSets the level of debugging information (default = 1)\n" ;
	print "\t[-force]\t\t\t\tReplaces existing views without asking!\n" ;
	print "\t[-dynamicView <streamname>]\t\tCreate a Dynamic View\n" ;
	print "\t[-emptyView <streamname>]\t\tCreate an Empty Snapshot View\n" ;
	print "\t[-obsoleteActivity <projectname>]\tObsolete a Projects Activities\n" ;
	print "\t[-obsoleteProject <projectname>]\tObsolete a Project entirely\n" ;
	print "\t[-rebaseStage]\t\t\t\tRebase & Load Staging View\n" ;
	print "\t[-removeView <viewname>]\t\tRemove View\n" ;
	print "\t[-rmAllViews]\t\t\t\tRemove All Your Views\n" ;
	print "\t[-snapView <streamname>]\t\tCreate a full Snapshot View: (Loads all files)\n" ;
	print "\t[-stageView <streamname>]\t\tCreate a Staging View: (Loads Baseline files) \n" ;
	print "\t[-streamView <streamname>]\t\tCreate a Stream View: (Loads Streams files)\n" ;
}

sub sub_information()
{
	(${debug} > 1) && &sub_debug(3, "sub_information") ;
	(${debug} < 1) && system(($^O eq 'MSWin32') ? 'cls' : 'clear') ; # Clears the screen
	my(${filename}) = basename $0 ;
	&sub_logmsg (3, "${filename} - Version: ${Version}") ;
	&sub_logmsg (3, "ClearCase Region Information: ${pvob}") ;
}

sub sub_interrupt()
{
	(${debug} > 1) && &sub_debug(3, "sub_interrupt") ;
	my($signal)=@_ ;
	die "\nInterrupt: Caught signal $signal exiting\n" ;
}

sub sub_logmsg()
{
	my ${msgType} = $_[0] ;
	my(${message}) = $_[1] ;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	if    (${msgType} == 1) { print "\nCL: ${message}\n" ; }
	elsif (${msgType} == 2) { print "\nInput: ${message}" ; }
	elsif (${msgType} == 3) { print "\nInfo: ${message}\n" ; }
	print (LOGFILE "\n$dttime{year}/$dttime{mon}/$dttime{mday} $dttime{hour}:$dttime{min}\t${message}") ;
}
	   
sub sub_ask()
{
	(${debug} > 1) && &sub_debug(3, "sub_ask") ;
	my(${question}) = $_[0] ;
	my(${ccobject}) = $_[1] ;
	&sub_logmsg(2, "${question}") ;
	chomp(${answer} = <STDIN>) ;
	if (${answer} =~ /^${user}_/i)
		{
		  ${answer} = $' ;
		}
	elsif (${answer} eq "")
		{
		  &sub_closeWait("-- ccUtil exiting --\n") ;
		}
	elsif (${answer} eq "?")
		{
		  &sub_listCCobject(${ccobject}) ;
		  &sub_ask(${question}, ${ccobject}) ;
		}
}

sub sub_snapView()
{
	(${debug} > 1) && &sub_debug(3, "sub_snapView") ;
	${cmd} = ${ct} . " mkview -snapshot -tag " . ${user} . "_" . ${project}{"stream"} . " -vws " . ${viewstore} . ${slash} . ${user} . "_" . ${project}{"stream"} . ".vws" . " -stream stream:" . ${project}{"stream"} . "@" . ${slash} . ${pvob} . " " . ${view} ;
	(${debug} > 0) && &sub_debug(1, ${cmd}) ;
	system("${cmd}") ;
	${exitlevel} = $? ;
}

sub sub_dynamicView()
{
	(${debug} > 1) && &sub_debug(3, "sub_dynamicView") ;
	${cmd} = ${ct} . " mkview -tag " . ${user} . "_" . ${project}{"stream"} . " -stream stream:" . ${project}{"stream"} . "@" . ${slash} . ${pvob} . " " . ${viewstore} . ${slash} . ${user} . "_" . ${project}{"stream"} . ".vws" ;
	(${debug} > 0) && &sub_debug(1, ${cmd}) ;
	system("${cmd}") ;
	${exitlevel} = $? ;
}

sub sub_validCCobject() 
{
	(${debug} > 1) && &sub_debug(3, "sub_validCCObject") ;
	my(${ccobject}) = @_ ;
	${cmd} = ${ct} . " ls" . ${ccobject}." -short ". ${project}{${ccobject}} . "@" . ${slash} . ${pvob} ;
	(${debug} > 0) && &sub_debug(1, ${cmd}) ;
	${valid} = `${cmd}` ;
	${exitlevel} = $? ;
	chomp(${valid}) ;
	(${valid} ne $project{${ccobject}}) && &sub_closeWait("Invalid ${ccobject}: \"$project{$ccobject}\" \n") ;
}

sub sub_listCCobject()
{
	(${debug} > 1) && &sub_debug(3, "sub_lsitCCobject") ;
	my(${ccobject}) = @_ ;
	if (${ccobject} eq "stream")
		{
		  ${cmd} = ${ct} . " ls" . ${ccobject} . " -fmt \"%n\t \" " . "-invob " . ${slash} . ${pvob} ;
		}
	elsif (${ccobject} eq "view")
		{
		  ${cmd} = ${ct} . " ls" . ${ccobject} . " -short " . ${user} . "*" ;
		}
	(${debug} > 0) && &sub_debug(1, ${cmd}) ;
	system("${cmd}") ;
	${exitlevel} = $? ;
	print "\n" ;
}

sub sub_projectDetails()
{
	(${debug} > 1) && &sub_debug(3, "sub_projectDetails") ;
	${cmd} = ${ct} . " lsproject -fmt \"%[istream]p\" " . ${project}{"project"} . "@" . ${slash} . ${pvob} ;
	(${debug} > 0) && &sub_debug(1, ${cmd}) ;
	${project}{"stream"} = `${cmd}` ;
	${exitlevel} = $? ;
	${project}{"brtype"} = `${cmd}` ;
	${exitlevel} = $? ;
	${cmd} = ${ct} . " lsstream -fmt \"%[activities]p\" " . ${project}{"stream"} . "@" . ${slash} . ${pvob} ;
	(${debug} > 0) && &sub_debug(1, ${cmd}) ;
	${project}{"activity"} = `${cmd}` ;
	${exitlevel} = $? ;
}

sub sub_unLock()
{
	(${debug} > 1) && &sub_debug(3, "sub_unLock") ;
	my(${ccobject}) = @_ ;
	${cmd} = ${ct} . " unlock " . ${ccobject} . ":" . ${project}{${ccobject}} . "@" . ${slash} . ${pvob} ;
	(${debug} > 0) && &sub_debug(1, ${cmd}) ;
	system("${cmd}") ;
	${exitlevel} = $? ;
}
	
sub sub_obsolete()
{
	(${debug} > 1) && &sub_debug(3, "sub_obsolete") ;
	my(${ccobject}) = @_ ;
	@{ccobject} = split / /, ${project}{${ccobject}} ;
	if (${ccobject} eq "project")
		{
		  ${cmd} = ${ct}." chproject -to folder:Obsolete ".${project}{${ccobject}}."@".${slash}.${pvob} ;
		  (${debug} > 0) && &sub_debug(1, ${cmd}) ;
		  system("${cmd}") ;
		  ${exitlevel} = $? ;
		}
	foreach (@{ccobject})
	{
	  ${cmd} = ${ct}." lock -obsolete -replace ".${ccobject}.":".$_."@".${slash}.${pvob} ;
	  (${debug} > 0) && &sub_debug(1, ${cmd}) ;
	  system("${cmd}") ;
	  ${exitlevel} = $? ;
	}
}

sub sub_validateView()
{
	(${debug} > 1) && &sub_debug(3, "sub_validateView") ;
	${view} = ${viewroot} . ${slash} . ${user} . "_" . ${project}{"stream"} ;
	${cmd} = ${ct} . " lsview -long -properties -full " . ${user} . "_" . ${project}{"stream"} ;
	(${debug} > 0) && &sub_debug(1, ${cmd}) ;
	${valid} = `${cmd}` ;
	${exitlevel} = $? ;
	if ((${valid} =~ /$user.$project{"stream"}/i) and (defined ${force}))
		{
		  &sub_rmView ;
		}
	elsif ((${valid} =~ /$user.$project{stream}/i) and (! defined ${force}))
	 	{
	 	  &sub_ask("Remove existing ClearCase View: ${user}_$project{\"stream\"} ? [Y/N]: ") ;
	 	  if (${answer} =~ /\bN\b/i)
	 	  	{
	 	  	  (! defined ${noexit}) && &sub_closeWait("-- ccUtil exiting --\n") ;
	 	  	}
	 	  else
	 	  	{
	 	  	  &sub_rmView ;
	 	  	}
		}
}

sub sub_rmView()
{
	(${debug} > 1) && &sub_debug(3, "sub_rmView") ;
	chdir ${viewroot};
	my(${dynamic}) = (${valid} =~ /dynamic/) ;
	if (${dynamic}) { ${tag} = "-tag " ;	}
	else { ${tag} = " " ;	}
	${cmd} = ${ct} . " rmview " . ${tag} . ${user} . "_" . ${project}{"stream"} ;
	(${debug} > 0) && &sub_debug(1, ${cmd}) ;
	system("${cmd}") ;
	${exitlevel} = $? ;
}

sub sub_rmAllViews()
{
	(${debug} > 1) && &sub_debug(3, "sub_rmAllViews") ;
	${cmd} = ${ct} . " lsview -short " . ${user} . "*" ;
	${myViews} = `${cmd}` ;
	${exitlevel} = $? ;
	${noexit} = "noExit" ;
	@{myViews} = split /\n/, ${myViews} ;
	foreach (@{myViews})
		{
		  /^${user}_/i ;
		  ${removeView} = $' ;
		  ${project}{"stream"} = ${removeView} ; 
		  &sub_validateView ;
		}
}	

sub sub_baselines()
{
	(${debug} > 1) && &sub_debug(3, "sub_baselines") ;
	my(${blType}) = @_ ;
	chdir ${view} or &sub_closeWait("Can't change directory to ${view}: $!\n") ;
	${cmd} = ${ct} . " lsstream -fmt \"%[${blType}]p\" " . ${project}{"stream"} . "@" . ${slash} . ${pvob} ;
	(${debug} > 0) && &sub_debug(1, ${cmd}) ;
	${baseline} = `${cmd}` ;
	${exitlevel} = $? ;
	@{baselines} = split / /, ${baseline} ;
}

# Subroutine to rebase a staging stream. A baseline entered with a '-' will result in that baseline being removed.
sub sub_rebase()
{
	(${debug} > 1) && &sub_debug(3, "sub_rebase") ;
	&sub_baselines(@_) ;
	&sub_logmsg (3, "Current Foundation Baselines: @{baselines}") ;
	&sub_ask("Enter new Baseline: ") ;
	${baseline} = ${answer} ;
	if (${baseline} =~ /-.*/)
		{
		  ${blcmd} = "-dbaseline" ;
		  ${baseline} =~ s/-// ;
		}
	else { ${blcmd} = "-baseline" ;	}
	${cmd} = ${ct} . " lsbl -short " . ${baseline} . "@" . ${slash} . ${pvob} ;
	(${debug} > 0) && &sub_debug(1, ${cmd}) ;
	${valid} = `${cmd}` ;
	${exitlevel} = $? ;
	if (${valid} =~ /${baseline}/)
		{
		  ${cmd} = ${ct} . " rebase -complete -view " . ${user} . "_" . ${project}{"stream"} . " " . ${blcmd} . " " . ${baseline} . "@" . ${slash} . ${pvob} ;
		  (${debug} > 0) && &sub_debug(1, ${cmd}) ;
		  system("${cmd}") ;
		  ${exitlevel} = $? ;
		}
	else { &sub_closeWait("Baseline not recognised: ${baseline}\n") ; }
}

sub sub_baselineComponents()
{
	(${debug} > 1) && &sub_debug(3, "sub_baselineComponents") ;
	my(${baseline}) = @_ ;
	${cmd} = ${ct} . " lsbl -fmt \"%[component]p\" " . ${baseline} . "@" . ${slash} . ${pvob} ;
	(${debug} > 0) && &sub_debug(1, ${cmd}) ;
	${component} = `${cmd}` ;
	${exitlevel} = $? ;
}

# Subroutine to load just the files identified by a Baseline
sub sub_baselineElements()
{
	(${debug} > 1) && &sub_debug(3, "sub_baselineElements") ;
	my(${blType}) = @_ ;
	&sub_baselines(${blType}) ;
	foreach (@{baselines})
	{
		&sub_baselineComponents($_) ;
		${cmd} = ${ct} . " find " . ${component} . " -type f -nxname -element \"lbtype_sub(" . $_ . ")\" -exec \"cmd /c echo load \"\"\\%CLEARCASE_PN%\"\"\" >> " . ${share_dir} . ${slash} . "Views" . ${slash} . ${user} . "_" . ${project}{"stream"} . ".vws" . ${slash} . "config_spec" ;
		(${debug} > 0) && &sub_debug(1, ${cmd}) ;
		system("${cmd}") ;
		${exitlevel} = $? ;
	}
}

# Subroutine to load just the files identified by a Stream
sub sub_streamElements()
{
	(${debug} > 1) && &sub_debug(3, "sub_streamElements") ;
	my(${blType}) = @_ ;
	&sub_baselines(${blType}) ;
	foreach (@{baselines})
	{
		&sub_baselineComponents($_) ;
		${cmd} = ${ct} . " find " . ${component} . " -type f -nxname -element \"brtype(" . ${project}{"stream"} . ")\" -exec \"cmd /c echo load \"\"\\%CLEARCASE_PN%\"\"\" >> " . ${share_dir} . ${slash} . "Views" . ${slash} . ${user} . "_" . ${project}{"stream"} . ".vws" . ${slash} . "config_spec" ;
		(${debug} > 0) && &sub_debug(1, ${cmd}) ;
		system("${cmd}") ;
		${exitlevel} = $? ;
	}
}

# Subroutine to load all the conponents files
sub sub_loadComponents()
{
	(${debug} > 1) && &sub_debug(3, "sub_loadComponents") ;
	${config_spec} = ${share_dir} . ${slash} . "Views" . ${slash} . ${user} . "_" . ${project}{"stream"} . ".vws" . ${slash} . "config_spec" ;
	open (CONFIG_SPEC, ">>", ${config_spec}) ;
	&sub_baselines(@_) ;
	foreach (@{baselines})
	{
		&sub_baselineComponents($_) ;
		print (CONFIG_SPEC "load \\${component}\n") ;
	}
	close CONFIG_SPEC ;
}

sub sub_updateView()
{
	(${debug} > 1) && &sub_debug(3, "sub_updateView") ;
	&sub_logmsg (3, "Updating View: ${user}_$project{stream}") ;
	${cmd} = ${ct} . " setcs -current" ;
	(${debug} > 0) && &sub_debug(1, ${cmd}) ;
	system("${cmd}") ;
	${exitlevel} = $? ;
}

sub sub_closeWait()
{
	(${debug} > 1) && &sub_debug(3, "sub_closeWait") ;
	my(${message}) = @_ ;
	&sub_logmsg(3, ${message});
	if (! defined ${force})
		{
		  print "<Return> to close ..." ;
		  <STDIN> ;
		}
	(${debug} > 1) && &sub_debug(3, "Exit Level: ${exitlevel}") ;
	close LOGFILE ;
	exit ${exitlevel} ;
}
	
###########################	
##                       ##    
## Start of Main Program ##
##                       ##    
###########################	

# Check for Debug Mode
	if (${debug})
		{
		   (${debug} > 1) && &sub_debug(3, "Debug") ;
		}
	
# ClearCase Region Notification
	&sub_information ;
	
# Check for Force Mode
	if (${force})
		{
		  (${debug} > 1) && &sub_debug(3, "Force") ;
		  &sub_logmsg(3, "Force");
		  ${force} = "YES" ;
		}
			
# Change directory to C:\Data\ClearCase\ViewRoot as UNC Paths are not supported
	chdir ${viewroot} ;

# Ask for Stream Name if not supplied

	if (defined ${stageView})
		{
		(${debug} > 1) && &sub_debug(3, "Stage View") ;
		if (${stageView} eq "")
			{
		  	  &sub_ask("Enter Stage Project Stream Name: ", "stream") ;
		  	  ${project}{"stream"} = ${answer} ;
		  	}
		else
			{
		  	  ${project}{"stream"} = ${stageView} ;
			}
		  &sub_validateView(${project}{"stream"}) ;
		  &sub_validCCobject("stream") ;
		  &sub_snapView ;
		  &sub_baselineElements("found_bls") ;
		  &sub_updateView ;
		}
	elsif (defined ${streamView})
		{
		  (${debug} > 1) && &sub_debug(3, "Stream View") ;
		  if (${streamView} eq "")
		  	{
		  	  &sub_ask("Enter Project Stream Name: ", "stream") ;
		  	  ${project}{"stream"} = ${answer} ;
		  	}
		  else
		  	{
		  	  ${project}{"stream"} = ${streamView} ;
		  	}
		  &sub_validateView(${project}{"stream"}) ;
		  &sub_validCCobject("stream") ;
		  &sub_snapView ;
		  &sub_streamElements("found_bls") ;
		  &sub_updateView ;
		}
	elsif (defined ${snapView})
		{
		  (${debug} > 1) && &sub_debug(3, "Snapshot View") ;
		  if (${snapView} eq "")
		  	{
		  	  &sub_ask("Enter Project Stream Name: ", "stream") ;
		  	  ${project}{"stream"} = ${answer} ;
		  	}
		  else
		  	{
		  	  ${project}{"stream"} = ${snapView} ;
		  	}
		  &sub_validateView(${project}{"stream"}) ;
		  &sub_validCCobject("stream") ;
		  &sub_snapView ;
		  &sub_loadComponents("latest_bls") ;
		  &sub_updateView ;
		}
	elsif (defined ${dynamicView})
		{
		  (${debug} > 1) && &sub_debug(3, "Dynamic View") ;
		  if (${dynamicView} eq "")
		  	{
		  	  &sub_ask("Enter Project Stream Name: ", "stream") ;
		  	  ${project}{"stream"} = ${answer} ;
		  	}
		  else
		  	{
		  	  ${project}{"stream"} = ${dynamicView} ;
		  	}
		  &sub_validateView(${project}{"stream"}) ;
		  &sub_validCCobject("stream") ;
		  &sub_dynamicView ;
		}
	elsif (defined ${emptyView})
		{
		  (${debug} > 1) && &sub_debug(3, "Empty View") ;
		  if (${emptyView} eq "")
		  	{
		  	  &sub_ask("Enter Project Stream Name: ", "stream") ;
		  	  ${project}{"stream"} = ${answer} ;
		  	}
		  else
		  	{
		  	  ${project}{"stream"} = ${emptyView} ;
		  	}
		  &sub_validateView(${project}{"stream"}) ;
		  &sub_validCCobject("stream") ;
		  &sub_snapView ;
		}
	elsif (defined ${removeView})
		{
		  (${debug} > 1) && &sub_debug(3, "Remove View") ;
		  if (${removeView} eq "")
		  	{
		  	  &sub_ask("Enter Project View Name to Remove: ", "view") ;
		  	  ${project}{"stream"} = ${answer} ;
		  	}
		  elsif (${removeView} =~ /^${user}_/i)
		  	{
		  	  ${removeView} = $' ;
		  	  ${project}{"stream"} = ${removeView} ;
		  	}
		  else
		  	{
		  	  ${project}{"stream"} = ${removeView} ;
		  	}
		  &sub_validateView(${project}{"stream"}) ;
		}
	elsif (defined ${rmAllViews})
		{
		  (${debug} > 1) && &sub_debug(3, "Remove All My Views") ;
		  &sub_rmAllViews ;
		}
	elsif (${rebaseStage})
		{
		  (${debug} > 1) && &sub_debug(3, "Rebase View") ;
		  &sub_ask("Enter Project Stream Name to Rebase: ", "stream") ;
		  ${project}{"stream"} = ${answer} ;
		  &sub_validateView(${project}{"stream"}) ;
		  &sub_validCCobject("stream") ;
		  &sub_snapView ;
		  &sub_rebase("found_bls") ;
		  &sub_baselineElements("found_bls") ;
		  &sub_updateView ;
		}
	elsif (defined ${obsoleteActivity})
		{
		  (${debug} > 1) && &sub_debug(3, "Obsolete Activity") ;
		  if (${obsoleteActivity} eq "")
		  	{
		  	  &sub_ask("Enter Project containing Activities: ", "project") ;
		  	  ${project}{"project"} = ${answer} ;
		  	}
		  else
		  	{
		  	  ${project}{"stream"} = ${obsoleteActivity} ;
		  	}
		  &sub_validCCobject("project") ;
		  &sub_projectDetails(${project}{"project"}) ;
		  &sub_obsolete("activity") ;
		}
	elsif (defined ${obsoleteProject})
		{
		  (${debug} > 1) && &sub_debug(3, "Obsolete Project") ;
		  if (${obsoleteProject} eq "")
		  	{
		  	  &sub_ask("Enter Project Name to Obsolete: ", "project") ;
		  	  ${project}{"project"} = ${answer} ;
		  	}
		  else
		  	{
		  	  ${project}{"project"} = ${obsoleteProject} ;
		  	}
		  &sub_validCCobject("project") ;
		  &sub_projectDetails(${project}{"project"}) ;
		  &sub_unLock("project") ;
		  &sub_unLock("stream") ;
		  &sub_obsolete("activity") ;
		  &sub_obsolete("brtype") ;
		  &sub_obsolete("stream") ;
		  &sub_obsolete("project") ;
		}		
	else
		{
		  (${debug} > 1) && &sub_debug(3, "Invalid Option") ;
		  &sub_usage ;
		}
				
# Clean and Close 
	&sub_closeWait("-- ccUtil completed --\n") ;
	