require! gulp
require! browserify: 'gulp-browserify'
require! sass: 'gulp-sass'
require! jade: 'gulp-jade'
require! rename: 'gulp-rename'
require! express
require! httpRewrite: 'http-rewrite-middleware'
require

appDist = './dist/app'
appStub = './dist/stub'
appVendor = "#{appDist}/vendor"

dist = -> gulp.dest(appDist)
gtask = gulp~task
gsrc = gulp~src

gtask 'default', ['build']

gtask 'build', ['livescript', 'vendor', 'sass', 'jade', 'stub']

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
    .pipe dist()

gtask 'jade', ->
  gsrc './app/*.jade'
    .pipe jade()
    .pipe dist()

gtask 'stub', ->
  gsrc './stub/**/*', base: './stub'
    .pipe gulp.dest(appStub)

gtask 'server', ['build'] ->
  server = express()
  rewriteRules =
    * from: '^(/api/.*?)/?([?].*)?$', to: '$1.json$2'
    ...
  
  server.use httpRewrite.getMiddleware(rewriteRules, verbose: true)
  server.use(express.static(appDist))
  server.use(express.static(appStub))
  
  liveServer = server.listen 3000, ->
    console.log("Started server on port #{liveServer.address().port}")

gtask 'watch', ['server'] ->
  gulp.watch ['./app/js/**/*.ls'], ['livescript']
  gulp.watch ['bower_components/**/*'], ['vendor']
  gulp.watch ['app/css/**/*.scss'], ['sass']
  gulp.watch ['app/**/*.jade'], ['jade']
  gulp.watch ['stub/**/*'], ['stub']