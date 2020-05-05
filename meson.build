project('de.hannenz.podsblitz', 'vala', 'c')

gnome = import('gnome')
i18n = import('i18n')

add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    language: 'c'
)

subdir('src')

asresources = gnome.compile_resources(
    'as-resources',
    join_paths('data', meson.project_name()) + '.gresource.xml',
    source_dir: 'data',
    c_name: 'as'
)

dependencies = [
    dependency('gtk+-3.0'),
	dependency('sqlite3'),
	dependency('libxml-2.0'),
	dependency('gee-0.8'),
	dependency('libsoup-2.4'),
	meson.get_compiler('vala').find_library('posix')
]

executable(
    meson.project_name(),
    sources,
    asresources,
    dependencies: dependencies,
    install: true
)

subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py')
