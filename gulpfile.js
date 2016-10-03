var gulp = require('gulp');
var del = require('del');
var elm  = require('gulp-elm'); 

gulp.task('elm-init', elm.init);

gulp.task('clean', function(){
    return del([
        'elm-stuff/build-artifacts/*/user'
    ]);
});

gulp.task('build', ['elm-init'], function(){
  return gulp.src('src/*.elm')
    .pipe(elm.bundle('lib.js',{warn:true}))
    .pipe(gulp.dest('build/'));
});

gulp.task('rebuild', ['clean', 'build']);

gulp.task('test', ['build'], function(){
    return gulp.src(['src/*.elm', 'test/*.elm'])
    .pipe(elm.bundle('raw-test.js'))
    .pipe(gulp.dest('build/'));
})

gulp.task('default', function() {
  // place code for your default task here
});
