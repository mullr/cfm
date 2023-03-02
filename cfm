#!/usr/bin/perl -w
#     cfm - Russell P. Mull

use strict;
use Tk;
use Cwd;
require Tk::HList;
require Tk::ItemStyle;
require Tk::Dialog;

my $pwd = cwd();

push (my @owd, $pwd);                   # owd is the variable containing the
					# Old Working Directory... that is the
					# directory that we were in before the
					# current directory.

                                        # the following are the variables that
                                        # act as hooks for rc file
my $xterm  = "xterm";
my $editor = "$xterm -e ";
$editor .= (exists($ENV{'VISUAL'}))  ? $ENV{'VISUAL'} :
           (exists ($ENV{'EDITOR'})) ? $ENV{'EDITOR'} : "ed";
my $txtviewer   = "$xterm -e less";
my $htmlbrowser = "netscape";
my $imageviewer = "ee";
my $mpgplayer   = "gtv";
my $relief      = 'flat';
my $menurelief  = 'raised';
my $background  = "lightGrey";
my $foreground  = "black";
my $font        = '6x10';
my $compiler    = "cc";
my $compopt     = "";
my $make        = "make";
my $debug       = "$xterm gdb";
my $debugopt    = "";
my $lint        = "lclint";
my $lintopt     = "";
my $archiver    = "tar";
my $archiveopt  = "-cvzf";
my $compressor  = "gzip";
my $compressopt = "-9";
my $icancu      = 0;
my $owdlimit    = 25;
my $extras = 0;

my $bin_dir = "/usr/local/bin/";
my $dircolr = 'blue';
my $linkcolr = 'yellow';
my $execolr = 'sea green';
my $tearoff = 1;
my $version = "0.5";
my $dirs_at_top = 0;

my $window_width = 205;
my $window_height = 400;

my $limit_string = "";

my %mime_defs =
  (
   "\\.txt\$"     => "text/plain",
   "\\.mpg\$"     => "video/mpeg",
   "\\.mpeg\$"    => "video/mpeg",
   "\\.mp3\$"     => "audio/mpeg",
   "\\.m3u\$"     => "text/xmms-playlist",
   "\\.html\$"    => "text/html",
   "\\.htm\$"     => "text/html",
   "\\.ps\$"      => "application/postscript",
   "\\.jpg\$"     => "image/jpeg",
   "\\.jpeg\$"    => "image/jpeg",
   "\\.gif\$"     => "image/gif",
   "\\.tif\$"	  => "image/tif",
   "\\.png\$"     => "image/png",
   "\\.mid\$"     => "audio/midi",
   "\\.c\$"       => "text/x-c",
   "\\.tar\\.gz\$"  => "application/x-tar-gzip",
   "\\.gz\$"      => "application/x-gzip",
   "\\.tgz\$"     => "application/x-tar-gzip",
   "\\.tar\$"     => "application/x-tar",
   "\\.eps\$"     => "application/postscript"
  );

my %mime_descriptions = 
  (
   "directory"  => "Directory",
   "text/plain" => "Plain Text",
   "video/mpeg" => "MPEG Video",
   "audio/mpeg" => "MPEG Audio",
   "text/xmms-playlist" => "XMMS Playlist",
   "text/html"  => "HTML Page",
   "application/postscript" => "Postscript File",
   "image/jpeg" =>  "JPEG Compressed Image",
   "image/gif"  => "GIF Compressed Image",
   "image/tif"  => "TIFF Image",
   "image/png"  => "PNG Image",
   "audio/midi" => "MIDI Sequence",
   "text/x-c"   => "C Source File",
   "application/x-gzip", => "Gzip comressed file", 
   "application/x-tar-gzip", => "Gzip compressed tar archive",
   "application/x-tar", => "Tarball"
  );

my %mime_actions =
  (
   "text/plain" => [["View", '$txtviewer %f &'],
		    ["Edit", '$editor %f']],
   "directory"  => [["Navigate", \&navigate],
		    ["CFM Here", \&spawnme],
		   ],
   "video/mpeg" => [["Play Video", '$mpgplayer %f &']],
   "audio/mpeg" => [["Play in XMMS", 'xmms %f &'],
		    ["Add to Playlist", 'xmms --enqueue %f &' ]],
   "text/xmms-playlist" => [["Open in XMMS" , 'xmms %f &']],
   "text/html"  => [['Open in Browser', '$htmlbrowser file:%f &'],
		    ['Open in Galeon',  'galeon file:%f &'],
		    ['Edit', '$editor %f &']],
   "application/postscript" => [['View with Ghostscript', 'gv %f &']],
   "image/jpeg" => [["View", '$imageviewer %f &']],
   "image/tif"  => [["View", '$imageviewer %f &']],
   "image/gif"  => [["View", '$imageviewer %f &']],
   "audio/midi" => [["Play with XPlayMidi", 'xplaymidi %f &'],
		    ["Play with timidity", '$xterm -e timidity %f &']],
   "application/x-tar-gzip" => [["View archive", '$xterm -e less %f &'],
			        ["Unpack archive", '$xterm -e tar xzvmf %f &'],
				["Uncompress tarball", 'gunzip %f &']],
   "application/x-tar" => [["View archive", '$xterm -e less %f &'],
			        ["Unpack archive", '$xterm -e tar xvmf %f &']],
   "application/x-gzip" => [["Uncompress File", 'gunzip %f &']]
  );


sub add_menu_action {
  my ($mime_type, $label, $command) = @_;
  my $temp;

  $temp = $mime_actions{$mime_type};
  push @$temp, [$label, $command];
};

my %mime_cache;

my $mw = MainWindow->new(
    -bg   => $background,
    -fg   => $foreground,
);

my $status_text = "Welcome to the Canine File Manager\n" . `date`;
chomp $status_text;

##############################################################################
#
# Read user settings from $HOME/.cfmrc
#
##############################################################################

my $rc_file = "";
if ( -e "$ENV{'HOME'}/.cfmrc") { 	 # Do the following if $HOME/.vshrc
    open(RCFILE, "$ENV{'HOME'}/.cfmrc"); # exists
    foreach (<RCFILE>) {
	chomp($_);
	s/\#.*$//g;                      # remove comments.
	$rc_file .= $_;
    }
    close(RCFILE);
    eval($rc_file);
}

$pwd = pop() if ($#ARGV >= 0);		# If the user specifies a directory on
					# the command line, it will be used.
					# for the pwd.

chdir $pwd;

my $hlist    = $mw->Scrolled("HList",
			     -separator  => "|",
 			     -scrollbars => 'ose',
			     -drawbranch => "false",
			     -selectmode => 'extended',
			     -highlightthickness => 0,
			     -selectborderwidth => 0,
			     -width => 1,
			     -height => 1
			    );


my $status_bar=$mw->Label(
    -relief => $relief,
    -borderwidth => 1,
    -bg => $background,
    -fg => $foreground,
    -font => $font,
    -justify => "left",
    -anchor => "w",
    -textvariable => \$status_text
);

my $input_frame=$mw->Frame( );

my $prompt_text;
my $input_prompt=$input_frame->Label(
    -relief => "flat",
    -borderwidth => 0,
    -bg => $background,
    -fg => $foreground,
    -font => $font,
    -justify => "left",
    -textvariable => \$prompt_text,
    -anchor => "w"
);

my $input_field=$input_frame->Entry(
    -relief => "flat",
    -borderwidth => 0,
    -bg => $background,
    -fg => $foreground,
    -font => $font,
    -justify => "left"
);


##### File size Functions #####

sub file_size {
  my $filename = shift;
  my $raw_size = -s $filename;
  return human_size($raw_size);
}

sub sel_size {
  my $total_size = 0;
  my $file;

  foreach (@_) {
    $total_size += -s $_;
    print "$_\n";
  }
  return human_size($total_size);
}

sub human_size {
  my $raw_size = shift;
  my $eng_size = $raw_size . " b";

  if ($raw_size > 1024) {
    my $kb_size = $raw_size/1024;
    $eng_size = sprintf("%2.0f", $kb_size) . " K";

    if($kb_size > 1024) {
      my $mb_size = $kb_size/1024;
      $eng_size = sprintf("%2.2f", $mb_size) . " M";
    }
  }

  return $eng_size;
}

######## End File Size Functions ##########
my $old_sel;

$hlist->configure(-browsecmd => sub {
		    my @sel = get_selection($hlist);
		    my $new = join(" ", @sel);

		    if($old_sel && ($new eq $old_sel)) {
		      return;
		    }
		    $old_sel = join(" ", @sel);
		    #print "updating\n";

		    if(scalar(@sel) == 1) {
		      $status_text = file_size($sel[0]) . "    ";
		      $status_text .= substr($hlist->info("selection"), 2, $window_width-3) . "\n";
		      $status_text .= substr(mime_get_description($sel[0]), 0, $window_width);
		      chomp $status_text;
		    } else {
		      $status_text = sel_size(@sel) . "    ";
		      $status_text .= "Multiple files\n";
		      $status_text .= " ";
		    }
		  }
		 );


# Define the styles for the listing
my $plain_style     = $hlist->ItemStyle('text', -foreground => $foreground, -background => $background, -font => $font);
my $directory_style = $hlist->ItemStyle('text', -foreground => $dircolr, -background => $background, -font => $font);
my $link_style      = $hlist->ItemStyle('text', -foreground => $linkcolr, -background => $background, -font => $font);
my $exec_style      = $hlist->ItemStyle('text', -foreground => $execolr, -background => $background, -font => $font);

# Configure the listbox in accordance with whatever's set
$hlist->configure(-command => \&openup, #called when an item is double clicked
		  -relief     => $relief,
		  -bg         => $background,
		  -fg         => $foreground,
		  -font       => $font );

# Define the base context (right-click) menu
my $context_menu = $hlist->Menu(-menuitems =>
				[ "-",
				  ['command'  => "Cut",
				   "-command" => \&cut,
				   "-accelerator" => "Ctl+X"],
				  ['command'  => "Copy",
				   "-command" => \&copy,
				   "-accelerator" => "Ctl+C"],
				  ['command'  => "Paste",
				   "-command" => \&paste,
				   "-accelerator" => "Ctl+V"],
				  ['command'  => "Rename/Move", 
				   "-command" => \&rename,
				   "-accelerator" => "Ctl+R"],
				  ['command'  => "Delete",
				   "-command" => \&rm ]
				],
				-relief => $menurelief,
				-bg => $background,
				-fg => $foreground,
				-font => $font,
				-tearoff   => 0
			   );
my $context_item_count = 0;

my $tempdir = "/tmp/cfm-$ENV{'USER'}";
if(! -d $tempdir) {
  system "mkdir $tempdir";
}

$hlist->bind("<ButtonPress-3>", [\&hlist_button3down, Ev('X'), Ev('Y'), Ev('s'), Ev('x'), Ev('y')]);
$hlist->bind("<ButtonRelease-3>", [\&hlist_button3up, Ev('X'), Ev('Y'), Ev('s'), Ev('x'), Ev('y')]);
$hlist->bind("<ButtonPress-1>", \&hlist_button1down);
$hlist->bind("<ButtonPress-2>", \&setmod);

# Some convenient keyboard bindings

$mw->bind("<Delete>", \&deletit);
# $mw->bind("<Left>", \&back);  # Pending a good history system
$mw->bind("<Control-h>", \&home);
$mw->bind("<F5>", \&refresh);
$mw->bind("<F1>", \&docs);
$mw->bind("<Control-q>", \&quit);
$mw->bind("<Control-g>", \&goto);
$hlist->bind("<KeyPress-u>", \&up);
$hlist->bind("<Control-x>", \&cut);
$hlist->bind("<Control-c>", \&copy);
$hlist->bind("<Control-v>", \&paste);
$hlist->bind("<Control-o>", \&openwith);
$hlist->bind("<Control-p>", \&printit);
$hlist->bind("<Control-r>", \&rename);
$hlist->bind("<KeyPress-l>", \&set_limit);
$hlist->bind("<KeyPress-slash>", \&isearch);
$hlist->bind("<Control-s>", \&isearch);

$hlist->bind("<KeyPress-j>", sub {
	       $hlist->eventGenerate("<KeyPress-Down>");
	     } );
$hlist->bind("<KeyPress-k>", sub {
	       $hlist->eventGenerate("<KeyPress-Up>");
	     } );

# Page up and Page down are actually "Prior" and "Next"
$hlist->bind("<KeyPress-b>", sub {
	       $hlist->eventGenerate("<KeyPress-Prior>");
	       } );

$hlist->bind("<KeyPress-space>", sub {
	       $hlist->eventGenerate("<KeyPress-Next>");
	     } );


$hlist->bind("<KeyPress-J>", sub {
	       $hlist->eventGenerate("<Shift-Down>");
	     } );
$hlist->bind("<KeyPress-K>", sub {
	       $hlist->eventGenerate("<Shift-KeyPress-Up>");
	     } );

$hlist->bind("<KeyPress-i>", sub {
	      my @sel = $hlist->info("selection");
	      my @bbox = $hlist->infoBbox($sel[0]);
	      &build_menu($context_menu, $hlist, @sel);
	      $context_menu->post($bbox[0]+$hlist->rootx+3, $bbox[3]+$hlist->rooty+3);
	      $context_menu->focus();
	      } );

$context_menu->bind("<KeyPress-j>", sub {
	       $context_menu->eventGenerate("<KeyPress-Down>");
	     } );
$context_menu->bind("<KeyPress-k>", sub {
	       $context_menu->eventGenerate("<KeyPress-Up>");
	     } );
$context_menu->bind("<KeyPress-i>", sub {
	       $context_menu->unpost();
	       $hlist->focus();
	     } );
$context_menu->bind("<Control-g>", sub {
	       $context_menu->unpost();
	       $hlist->focus();
	     } );
$context_menu->bind("<KeyPress-Escape>", sub {
	       $hlist->focus();
	     } );
$context_menu->bind("<KeyPress-Return>", sub {
	       $hlist->focus();
	     } );

sub hlist_button1down {
  $context_menu->unpost();
}

##### mime type functions #####
# mime_get_type($file)
# mime_get_description($file)
# mime_get_actions($file)

sub mime_get_type {
  my $file = shift;
  my $pattern;
  my $type = 0;


  #If the type is cached, just return it. 
  if ($mime_cache{$file}) {
    return $mime_cache{$file};
  } else {
    if(-d $file) {
      return "directory";
    }
    foreach $pattern ( keys %mime_defs ) {
      $file = lc $file; # pretend everything is lower case
      if ($file=~/$pattern/) {
	$type = $mime_defs{$pattern};
	$mime_cache{$file} = $type;
	return $type;
      }
    }
  }
}

sub mime_get_description {
  my $file = shift;
  my $type;
  my $desc;

  $type = mime_get_type($file);
  $desc = $mime_descriptions{$type};

  if(! $desc) {
    return "File type unknown";
  } else {
    return $desc;
  }
}

sub mime_get_actions {
  my $file = shift;
  my $type;
  my $actions_ref;

  $type = mime_get_type($file);
  $actions_ref = $mime_actions{$type};
  if(! $actions_ref) {
    $actions_ref = [];
  }
  return $actions_ref;
}
##### end mime type functions ####

##### Getstring functions #####
sub get_string_prompt {
  my ($prompt, $callback) = @_;

  $status_bar->packForget();

  $input_frame->pack( -fill => "x");
  $input_prompt->pack(-expand => 1,
		      -fill => "x");
  $input_field->pack(-expand => 1,
		     -fill => "x");


  $input_field->delete(0, "end");
  $input_field->focus();
  $input_field->bind("<Return>", sub {
		       $input_frame->packForget();
		       $input_prompt->packForget();
		       $input_field->packForget();

		       $status_bar->pack(-fill => "x");
		       $status_text = "Executing...\n ";
		       &$callback($input_field->get());
		       $status_text = "Done.\n ";

		       $input_field->configure("-validate" => "none");
		       $mw->bind("<KeyPress-u>", \&up);
		       $mw->bind("<Control-g>", \&goto);

		       $hlist->focus();
		     });

  $mw->bind("<KeyPress-u>", "");
  #Control-g cancels
  $mw->bind("<Control-g>", "");
  $mw->bind("<Control-g>", sub {
		       $input_frame->packForget();
		       $input_prompt->packForget();
		       $input_field->packForget();

		       $status_bar->pack(fill => "x" );

		       $input_field->configure("-validate" => "none");
		       $mw->bind("<KeyPress-u>", \&up);
		       $mw->bind("<Control-g>", \&goto);

		       $hlist->focus();
		     });

  $prompt_text = $prompt;
}


#### end Getstring functions ####


##### Dialog functions #####
sub get_choice_dialog {
  my $title = shift;
  my $message = shift;
  my $icon = shift;
  my @buttons = @_;

  my $dialog = $mw->Dialog( -title => $title,
			    -text => $message,
			    -bitmap => $icon,
			    -default_button => $buttons[1],
			    -buttons => \@buttons,
			    -fg => $foreground,
			    -bg => $background,
			    -font => $font);
  return $dialog->Show;
}

sub message_dialog {
  my ($title, $message, $icon) = @_;
  $mw->messageBox(-title => $title,
		  -text  => $message,
		  -type  => "OK",
		  -icon  => $icon,
		  -fg    => $foreground,
		  -bg    => $background,
		  -font  => $font );
}

##### end dialog functions ######

sub get_selection {
  my $hlist = shift;
  my @sel = $hlist->info("selection");
  my @filenames;
  foreach (@sel) {
    push @filenames, $hlist->info("data", $_);
  }
  return @filenames;
}

sub docommand {
  my $command = shift;
  my @sel = @_;
  my $file_str;

  foreach (@sel) {
    $file_str .= "\"$_\" ";
  }

  $command =~ s/%f/$file_str/;
  $command =~ s/(\$\w+)/$1/eeg; # replace the variable refs in the
                                # string with their values.  see man
                                # perlfaq4
  system($command);
}

sub build_menu {
  my $menu = shift;
  my $hlist = shift;

  my @selection = get_selection($hlist);
  # FIXME
  my $file = $selection[0]; # Build the menu from the first item in the
                            #  selection. This is arbitrary.
  my $pattern;
  my $role;
  my $menuitem;
  my @menuarr;

  if($context_item_count != 0) {
    $context_menu->delete(0, $context_item_count-1);
    $context_item_count = 0;
  }

  return if( ! $file);

  # If the file is executable, the first option is to run it
  if (( -X $file) && ( -f $file)) {
    $context_menu->insert($context_item_count, "command",
			  -label => "Run",
			  -command => [\&docommand, '$xterm -e %f &', @selection]
			 );

    $context_item_count++;
  }

  # Get the mime type of the file from the regular expression table
  # and add the accociated menu items

  my $actions_ref = mime_get_actions($file);
  my @actions_arr = @{$actions_ref};
  my $item;

  if($#actions_arr < 0) {  #If none of the types match, see if it's a special file
    if(-T $file) {
      $actions_ref = $mime_actions{"text/plain"};
    } elsif (-d $file) {
      $actions_ref = $mime_actions{"directory"};
    }
    @actions_arr = @$actions_ref;
  }

  foreach $item (@actions_arr) {
    if (ref($item->[1]) eq "CODE") { #If it's a chunk of code, pass it directly
      $context_menu->insert($context_item_count++, "command", 
			    -label => $item->[0],
			    -command => [$item->[1], $file, @selection]
			   );
    } else {			#If it's a string, interpret it as a shell command
      $context_menu->insert($context_item_count++, "command", 
			    -label => $item->[0],
			    -command => 
			    [\&docommand, $item->[1], @selection]
			   );
    }
  }

  if ($context_item_count == 0) { #fallback viewer
    $context_menu->insert($context_item_count++, "command", 
			  -label => "View with less",
			  -command => 
			  [\&docommand, '$xterm -e less %f &', @selection]
			 );
  }
}

sub hlist_button3down {
  my $hlist = shift;
  my $X = shift;
  my $Y = shift;
  my $state = shift;
  my $x = shift;
  my $y = shift;

  my @sel = $hlist->info("selection");

  if ($#sel < 1) {
    $hlist->eventGenerate("<ButtonPress-1>",
			  -state => $state,
			  -x => $x,
			  -y => $y
			 );
  }

  &build_menu($context_menu, $hlist, @sel);
  $context_menu->post($X, $Y);
  $context_menu->focus();
}

sub hlist_button3up {
  my $hlist = shift;
  my $X = shift;
  my $Y = shift;
  my $state = shift;
  my $x = shift;
  my $y = shift;

  $hlist->eventGenerate("<ButtonRelease-1>", 
			-state => $state, 
			-x => $x, 
			-y => $y
		       );
}


sub getdir {
  my $hlist = shift();
  my $filename_orig;

  $hlist->delete("all");
  undef %mime_cache;   # This clears the mime type cache.

  $mw->title("CFM - $pwd");  # Set the window title


  opendir(PWD, $pwd) or die "$0: $pwd: $!\n"; # Read the directory
                                              # into the listbox.


  my @dirarr;
  if($dirs_at_top) {  # Display directories at the top
    my @filearr;
    my @basearr = sort readdir PWD;
    foreach (@basearr) {
      if (-d "$pwd/$_") {
	push @dirarr, $_;
      } else {
	push @filearr, $_;
      }
    }
    push @dirarr, @filearr;

  } else {
    @dirarr = sort readdir PWD;
  }

  foreach (@dirarr) { 
    $filename_orig = $_;
    if($limit_string) {
      next if(!($_ =~ $limit_string));
    }

    if ((substr($_, 0, 1) ne ".") ||
	($icancu) || 
        ($_ eq "..")) {

      my $style = $plain_style;

      if ( -d $pwd . "/" . $_) {
	$_ = "/ " . $_;	                    # '/' signifies a directory 
	$style = $directory_style;
      } elsif ( -X $pwd . "/" . $_) {
	$_ = "* " . $_;	                    # '*' signifies an executable
	$style = $exec_style;
      } elsif ( -l $pwd . "/" . $_) {
	$_ = "@ " . $_;                     # '@' for symbolic links
	$style = $link_style;
      } else {
	$_ = "  " . $_;
      }

      $hlist->add("$_", 
		  -text => $_, 
		  -data => $pwd . '/' . $filename_orig,
		  -style => $style
		  );
    }
  }
  closedir(PWD);
  chdir ($pwd);
}

# Delete a file.
# RENAME ME!!!!
sub deletit
{
  if(! -d "$ENV{'HOME'}/.waste-basket") {
    system "mkdir $ENV{'HOME'}/.waste-basket";
  }

  my @sel = get_selection($hlist);
  foreach (@sel) {

    if (( -f $_) && ( -W $_)) {                  # If its a file,
                                                 # throw it in the
						 # waste-basket.

      system "mv \"$_\" $ENV{'HOME'}/.waste-basket";
      getdir($hlist);
    }
  }
}

sub navigate {
  my $dir = shift;

  # Go to higher level directories properly
  # This regexp seems to work, but it's probably buggy
  if ($dir =~ /^(.*)\/(.*)\/\.\.$/) {
    $dir = $1;
    $dir = "/" if $dir eq "";
  }

  push(@owd,$pwd);
  shift(@owd) if (($owdlimit) && ($#owd > $owdlimit));

  if((-e $dir) && (-d $dir)) {
    $pwd = $dir;
  }

  getdir $hlist;
}

# Called when something is double clicked
sub openup() {
  # Get the selection and build the menu, then execute the top item
  &build_menu($context_menu, $hlist);
  $context_menu->invoke(0);
}

sub quit()
{
    exit;
}

sub rm()
{
    deletit($hlist, get_selection($hlist));
}

sub openwith()
{
  foreach (get_selection($hlist)) {
    if (!fork ()) {
      my $program = `getstr "Open With" "Open with ..."`;
      exec "$program $_ | show-output" ;
    }
  }
}

sub newfile()
{
  #my $filename = `getstr "Create File" "New filename:"`;
  my $filename = get_string_dialog("Create File",
				    "New File",
				    "question",
				    "Ok", "Cancel");

  system("$editor \"$filename\" &");
  getdir($hlist);
}

sub refresh()
{
    getdir($hlist);
}

sub home()
{
    push(@owd, $pwd);
    shift(@owd) if (($owdlimit) && ($#owd > $owdlimit));
    $pwd = $ENV{'HOME'};
    getdir($hlist);
}

sub root()
{
    push(@owd, $pwd);
    shift(@owd) if (($owdlimit) && ($#owd > $owdlimit));
    $pwd = "/";
    getdir($hlist);
}

sub up()
{
  navigate "$pwd\/..";
}

sub back()
{
  if ($#owd) {
    $pwd = pop(@owd);
    getdir($hlist);
  } else {
    print "\a";
  }
}

sub about()
{
  message_dialog("About", "Canine File Manager version $version\nCopyright(C) 2001 Russell Mull\nOriginally VSH, by Dowe Keller",
		 "questhead");
}

sub reload() {
  exec("vsh");
}

sub goto() {
  get_string_prompt("Go to directory:", sub {
		      my $newpwd = pop;

		      if(! ($newpwd =~ /^\//)) {  #If it's a relative path
			my $char = "";
			if(! ($pwd =~ /\/$/) ) {
			  $char = "/";
			}
			$newpwd = $pwd . $char . $newpwd;
		      }

		      if(! $newpwd) {
			return;
		      }
		      if(! -d $newpwd) {
			print "\a";
			return;
		      }

		      $pwd = $newpwd;
		      getdir($hlist);
		    });
}

sub newdir()
{
  get_string_prompt("Create new directory:", sub {
		      my $newdir = pop;
		      if(! $newdir) {
			return;
		      }
		      $newdir = "$pwd/$newdir" if ($newdir =~ /^[^\/]/);
		      system("mkdir \"$newdir\"");
		      getdir($hlist);
		    } );
}

sub set_limit {
  get_string_prompt("Limit to files matching:", sub {
		      $limit_string = pop;
		      getdir($hlist);
		    } );
  $input_field->insert("end", $limit_string);
  $input_field->selectionRange(0, "end");
}

sub isearch {
  get_string_prompt("I-search:", sub { 
		      $input_field->configure("-validate" => "none");
		    } );

  $input_field->configure("-validate" => "key");
  $input_field->configure("-validatecommand" => sub {
			    my ($newVal, $added, $oldVal, $index, $actiontype) = @_;
			    return 1 if $newVal eq "";
			    $hlist->anchorClear();

			    for($hlist->info("children")) {
			      if(substr($_, 2) =~ "^$newVal") {
				$hlist->selectionSet($_);
				$hlist->anchorSet($_);
			      } else {
				$hlist->selectionClear($_);
			      }
			    }
			    return 1;
			  } );
}

sub rename()
{
  my @sel = get_selection($hlist);

  #If it's a multiple selection
  if(scalar(@sel) > 1) {
    get_string_prompt("Move files to:", sub {
			my $destdir = pop;
			if(! $destdir){
			  return;
			}
			for (@sel) {
			  $status_text = system("mv \"$_\" \"$destdir\"");
			}
			getdir($hlist);
		      });
    $input_field->set($sel[0]);
  }
  #If only one file is selected
  else {
    my $file = $sel[0];
    if($file =~ /.*\/(.*)$/) {
      $file = $1;
    }
    get_string_prompt("Rename/Move $file to:", sub {
			my $newname = pop;
			if(! $newname) {
			  return;
			}
			if(! $newname =~ /\//) {
			  $newname = "$pwd/$newname";
			}
			$status_text = system("mv \"$pwd/$file\" \"$newname\"");
			getdir($hlist);
		      } );
  }
}

sub spawnme()
{
    system("$bin_dir/cfm &");
}

sub copyright() {
  system("$txtviewer /usr/local/doc/vsh/COPYING &");
}

sub edconf() {
  system("$editor $ENV{'HOME'}/.vshrc &");
}

sub empty() {
  system("rm -rf $ENV{'HOME'}/.waste-basket/* &");
}

sub homepage()
{
    system("$htmlbrowser http://www.rpi.edu/~mullr/cfm");
}

sub cut() {
  my $path;
  foreach $path (get_selection($hlist)) {
    system "mv \"$path\" $tempdir/";
  }
  getdir($hlist);
}

sub copy() {
  my $path;
  foreach $path (get_selection($hlist)) {
    system "cp -r \"$path\" $tempdir/";
  }
}

sub paste() {
  system "mv \"$tempdir\"/* $pwd";
  getdir($hlist);
}

sub su() {
  system("$xterm -e su &");
}

sub xterm() {
  system("$xterm &");
}

sub runit($) {
    system (pop());
}

sub menufactory() {
  my $parent = shift();
  my $menu = $parent->Menu(
     -menuitems => shift(),
     -font => $font,
     -relief => $menurelief,
     -fg => $foreground,
     -bg => $background,
     -tearoff => 0
  );
  return $menu;
}

my $menubar = $mw->Menu(-type => 'menubar',
		        -bg => $background,
		        -font => $font
			);

$mw->configure(-menu => $menubar);

my $file=$menubar->cascade(
			   -label => "~File",
			   -bg => $background,
			   -font => $font,
			   -tearoff => $tearoff,
			  );

my $file_menu = &menufactory($mw,
     [ ['command'  => "New Window",
        "-command" => \&spawnme ],
       ['command'  => "New Folder",
        "-command" => \&newdir,
        "-accelerator" => "Ctl-N"],
       ['command'  => "Empty Waste-basket",
        "-command" => \&empty ],
       ['command'  => "Quit",
        "-command" => \&quit,
        "-accelerator" => "Ctl-Q"] ] );

$file->configure(-menu => $file_menu);

my $edmenu=$menubar->cascade(
			     -label      => "~Edit",
			     -bg => $background,
			     -font => $font,
			     -tearoff   => $tearoff,
			     );

my $ed_menu = &menufactory($mw, 
	[ ['command'  => "Cut",
	   "-command" => \&cut,
	   "-accelerator" => "Ctl+X" ],
	  ['command'  => "Copy",
	   "-command" => \&copy,
	   "-accelerator" => "Ctl+C"],
	  ['command'  => "Paste",
	   "-command" => \&paste,
	   "-accelerator" => "Ctl+V"],
	  ['command'  => "Edit Configuration",
	   "-command" => \&edconf ],
	  ['command'  => "Reload .vshrc",
	   "-command" => \&reload ] ] );

$edmenu->configure(-menu => $ed_menu);

my $nav=$menubar->cascade(
    -label      => "~Navigate",
    -bg => $background,
    -font => $font,
    -tearoff   => $tearoff,
);

my $nav_menu=&menufactory($mw, 
  [ ['checkbutton' => "Show Hidden",
     "-variable" => \$icancu,
     "-command"  => \&refresh ],
    ['command'  => "Goto...",
     "-command" => \&goto,
     "-accelerator" => "Ctl+G"],
    ['command'  => "Previous",
     "-command" => \&back,
     "-accelerator" => "<-"],
    ['command'  => "History",
     "-command" => \&history ],
    ['command'  => "Home",
     "-command" => \&home,
     "-accelerator" => "Ctl-H"],
    ['command'  => "Refresh",
     "-command" => \&refresh,
     "-accelerator" => "F5"] ] );

$nav->configure(-menu => $nav_menu);

my $help = $menubar->cascade(
    -label  => "~Help",
    -bg => $background,
    -font => $font,
    -tearoff   => $tearoff
);

my $help_menu = &menufactory($mw, 
   [ ['command'  => "About",
      "-command" => \&about ], 
     ['command'  => "View Docs",
      "-command" => \&docs,
      "-accelerator" => "F1"],
     ['command'  => "View VSH Man Page",
      "-command" => \&vshman ],
     ['command'  => "View GPL",
      "-command" => \&copyright ],
     ['command'  => "Visit VSH Homepage",
      "-command" => \&homepage ],
     ['command'  => "View Man Pages",
      "-command" => \&man ],
     ['command'  => "Browse Info Pages",
      "-command" => \&infoo ] ] );

$help->configure(-menu => $help_menu);

getdir($hlist);

$hlist  -> pack (-fill => 'both',
		 -expand => 1);

$status_bar -> pack (-fill => "x",
		     -side => "left",
		     -expand => 1);

$mw->geometry($window_width . "x" . $window_height);
$hlist->focus();
MainLoop;
