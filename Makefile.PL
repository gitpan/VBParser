use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
push(@extras,
    AUTHOR        => 'Freydiere Patrice <frett@iname.com>'
    ) if ($ExtUtils::MakeMaker::Version >= 5.4301);
WriteMakefile(
    'NAME'		=> 'Language::VBParser',
    'VERSION_FROM'	=> 'VBParser.pm', # finds $VERSION
    'PREREQ_PM'		=> { Parse::RecDescent => '1.80' }, # e.g., Module::Name => 1.1
    'VERSION'		=> '0.01'
);
