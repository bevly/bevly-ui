require! gulp
require! browserify: 'gulp-browserify'
require! sass: 'gulp-sass'
require! csso: 'gulp-csso'
require! jade: 'gulp-jade'
require! rename: 'gulp-rename'
require! express
require! httpRewrite: 'http-rewrite-middleware'
require! proxy: 'proxy-middleware'
require! filter: 'gulp-filter'
require! rev: 'gulp-rev'
require! revReplace: 'gulp-rev-replace'
require! rimraf
require! url

appDist = './dist/app-tmp'
appStub = './dist/stub'
appOptimized = './dist/app'
appVendor = "#{appDist}/vendor"

dist = -> gulp.dest(appDist)
gtask = gulp~task
gsrc = gulp~src

gtask 'default', ['build']

gtask 'compile', ['livescript', 'vendor', 'sass', 'jade']
gtask 'build', ['rev', 'stub']

gtask 'clean', (cb) -> rimraf('dist', cb)

gtask 'rev', ['compile'] ->
  jsFilter = filter('**/*.js')
  cssFilter = filter('**/*.css')
  allButIndex = filter(['**/*', '!index.html'])
  gsrc "#{appDist}/**/*"
    .pipe allButIndex
    .pipe rev()
    .pipe allButIndex.restore()
    .pipe revReplace()
    .pipe gulp.dest(appOptimized)

gtask 'livescript', ->
  gsrc './app/js/app.ls', read: false
    .pipe browserify(transform: 'browserify-livescript',
                     extensions: '.ls',
                     debug: true)
    .pipe rename('app.js')
    .pipe dist()

gtask 'vendor', ->
  gsrc 'bower_components/**/*', base: 'bower_components'
    .pipe gulp.dest(appVendor)

gtask 'sass', ->
  gsrc './app/css/**/*.scss', base: './app/css'
    .pipe sass()
    .pipe csso()
    .pipe dist()

gtask 'jade', ->
  gsrc './app/*.jade'
    .pipe jade()
    .pipe dist()

gtask 'stub', ->
  gsrc './stub/**/*', base: './stub'
    .pipe gulp.dest(appStub)

gtask 'iserver', ['build'] ->
  server = express()
  server.use '/api/bevly', proxy(url.parse('http://localhost:3000'))  
  server.use(express.static(appOptimized))
  liveServer = server.listen 8181, ->
    console.log("Started server on port #{liveServer.address().port}")

gtask 'server', ['build'] ->
  server = express()
  rewriteRules =
    * from: '^(/api/.*?)/?([?].*)?$', to: '$1.json$2'
    ...
  
  server.use httpRewrite.getMiddleware(rewriteRules, verbose: true)
  server.use(express.static(appOptimized))
  server.use(express.static(appStub))
  
  liveServer = server.listen 3000, ->
    console.log("Started server on port #{liveServer.address().port}")

gtask 'serve', ['server']

gtask 'watch-compile' ->
  watches =
    './app/js/**/*.ls': ['livescript']
    'bower_components/**/*': ['vendor']
    'app/css/**/*.scss': ['sass']
    'app/**/*.jade': ['jade']
    'stub/**/*': ['stub']

  for own watch, action of watches
    gulp.watch(watch, action ++ ['rev'])
  
gtask 'watch', ['server', 'watch-compile']
gtask 'iwatch', ['iserver', 'watch-compile']