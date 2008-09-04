use inc::Module::Install 0.75;

name        'Catalyst-View-Graphics-Primitive';
all_from    'lib/Catalyst/View/Graphics/Primitive.pm';

test_requires 'Pod::Coverage::Moose';

requires    'Catalyst::Runtime' => 5.7014;
requires    'Class::MOP' => 0.65;
requires    'Graphics::Primitive' => 0.26;
requires    'Scalar::Util' => 1.19;

auto_install;

WriteAll;