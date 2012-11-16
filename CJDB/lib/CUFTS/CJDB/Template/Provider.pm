package CUFTS::CJDB::Template::Provider;

##
## This is a sub-class of Template Toolkit's Template::Provider.
## It provides checking for deleted templates.
##
use Template::Provider;
use base 'Template::Provider';

use constant PREV   => 0;
use constant NAME   => 1;
use constant DATA   => 2; 
use constant LOAD   => 3;
use constant NEXT   => 4;
use constant STAT   => 5;

$DEBUG = 0 unless defined $DEBUG;

sub _fetch_path {
    my ($self, $name) = @_;
    my ($size, $compext, $compdir) = 
	@$self{ qw( SIZE COMPILE_EXT COMPILE_DIR ) };
    my ($dir, $paths, $path, $compiled, $slot, $data, $error);
    local *FH;

    $self->debug("_fetch_path($name)") if $self->{ DEBUG };

    # caching is enabled if $size is defined and non-zero or undefined
    my $caching = (! defined $size || $size);

    INCLUDE: {

        # the template may have been stored using a non-filename name
        if ($caching && ($slot = $self->{ LOOKUP }->{ $name })) {
            # cached entry exists, so refresh slot and extract data
            ($data, $error) = $self->_refresh($slot);
            $data = $slot->[ DATA ] 
                unless $error;
            last INCLUDE;
        }
        
        $paths = $self->paths() || do {
            $error = Template::Constants::STATUS_ERROR;
            $data  = $self->error();
            last INCLUDE;
        };
        
        # search the INCLUDE_PATH for the file, in cache or on disk
        foreach $dir (@$paths) {
            $path = File::Spec->catfile($dir, $name);
            
            $self->debug("searching path: $path\n") if $self->{ DEBUG };
            
            if ($caching && ($slot = $self->{ LOOKUP }->{ $path })) {
                if (-e $path) {           
                    # cached entry exists (and file still exists), so refresh slot and extract data
                    ($data, $error) = $self->_refresh($slot);
                    $data = $slot->[ DATA ]
                        unless $error;
                    last INCLUDE;
                } else {
                    # cached entry exists, but the file it represents has been deleted.  Remove from cache.
                    
                    if ($self->{ HEAD } == $slot) {
                        $self->{ HEAD } = $slot->[ NEXT ];
                    } elsif ($self->{ TAIL } == $slot) {
			$self->{ TAIL } = $slot->[ PREV ];
                    }
                    
                    defined($slot->[ PREV ]) and
                        $slot->[ PREV ]->[ NEXT ] = $slot->[ NEXT ];
                        
                    defined($slot->[ NEXT ]) and
                        $slot->[ NEXT ]->[ PREV ] = $slot->[ PREV ];
                    
                    delete $self->{ LOOKUP }->{ $path };
                }
            }
            elsif (-f $path) {
                $compiled = $self->_compiled_filename($path)
                    if $compext || $compdir;
                
                if ($compiled && -f $compiled 
                    && (stat($path))[9] <= (stat($compiled))[9]) {
                    if ($data = $self->_load_compiled($compiled)) {
                        # store in cache
                        $data  = $self->store($path, $data);
                        $error = Template::Constants::STATUS_OK;
                        last INCLUDE;
                    }
                    else {
                        warn($self->error(), "\n");
                    }
                }
                # $compiled is set if an attempt to write the compiled 
                # template to disk should be made
                
                ($data, $error) = $self->_load($path, $name);
                ($data, $error) = $self->_compile($data, $compiled)
                    unless $error;
                $data = $self->_store($path, $data)
                    unless $error || ! $caching;
                $data = $data->{ data } if ! $caching;
                # all done if $error is OK or ERROR
                last INCLUDE if ! $error 
                    || $error == Template::Constants::STATUS_ERROR;
            }
        }
        # template not found, so look for a DEFAULT template
        my $default;
        if (defined ($default = $self->{ DEFAULT }) && $name ne $default) {
            $name = $default;
            redo INCLUDE;
        }
        ($data, $error) = (undef, Template::Constants::STATUS_DECLINED);
    } # INCLUDE
    
    return ($data, $error);
}

1;