var $ = window.$;

$('.calendar-list li').click(function() {
  var card = $(this).children('.calendar-card');
  card.slideDown(500);
});

$('.calendar-list li').mouseleave(function() {
  var card = $(this).children('.calendar-card');
  card.slideUp(500);
});
