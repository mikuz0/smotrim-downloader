project('smotrim-downloader', 'vala', 'c',
    version: '0.1.0',
    license: 'GPL3',
    default_options: ['prefix=/usr']
)

gtk = dependency('gtk+-3.0', version: '>=3.24')
glib = dependency('glib-2.0', version: '>=2.50')

prefix = get_option('prefix')
bindir = join_paths(prefix, get_option('bindir'))
datadir = join_paths(prefix, get_option('datadir'))
app_id = 'ru.smotrim.downloader'

conf = configuration_data()
conf.set('APP_ID', app_id)
conf.set('VERSION', meson.project_version())
conf.set('BINDIR', bindir)

subdir('src')
subdir('data')