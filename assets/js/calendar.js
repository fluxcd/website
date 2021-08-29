var $ = window.$;

$('.calendar-list li').click(function() {
  var card = $(this).children('.calendar-card');
  $('.calendar-card').not(card).slideUp(500);

  card.slideDown(500);
});
