use 5.030;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'InstaCombine',
    VERSION_FROM      => 'lib/InstaCombine.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
                          JSON => 0, 
                          HTTP::Request => 0,
                          HTTP::CookieJar::LWP => 0, 
                          LWP::UserAgent => 0, 
                          }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/InstaCombine.pm', # retrieve abstract from module
    AUTHOR            => 'little_bugger',
);
