$(function() {
    alert('hi');

  $(document).on('click', '#hit_form input', function() {
    alert('hi');

    $.ajax({
      type: 'POST',
      url: '/game/player/hit'
    }).done(function(msg) {
      $('#game').replaceWith(msg);
    });

    return false;
  });


});