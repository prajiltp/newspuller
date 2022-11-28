// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import 'jquery'
import 'jquery_ujs'
$(document).ajaxStart(function () {
  //show ajax indicator
  $('#result_loading').fadeIn(100);
}).ajaxStop(function () {
    //hide ajax indicator
    $('#result_loading').fadeOut(100);
    $('.carousel').carousel({ interval: 3000  });
});
