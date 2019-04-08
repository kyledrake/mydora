function getSong() {

  var req = {
    url: '/song.json',
    data: 'genre_id='+$("input[name='genre_id']:checked").val()
  }

  $.getJSON(req, function(data) {
    console.log(data)

    var song_artist = data.artist.name+' - '+data.song.name;

    if(data.artist.genres) {
      data.artist.genres.replace(/,/g, ', ');
    } else {
      data.artist.genres = ''
    }

    document.getElementById('control_panel').style.display = 'block';
    document.getElementById('filters').style.display = 'block';

    var player = document.getElementById('player');
    var history = document.getElementById('history');
    var history_cover = document.getElementById('history_cover');

    document.getElementById('play_button').innerText = 'Next Song'

    document.getElementById("song_info").innerText = song_artist;
    document.getElementById('genres').innerText = data.artist.genres;
    document.getElementById('location').innerText = data.artist.parsed_location;
    history.innerHTML = song_artist+'<br>'+document.getElementById('history').innerHTML;
    history_cover.style.display = 'block';
    document.getElementById("player_source").src = '/songs'+data.song.path;
    player.style.display = 'block';
    player.load();

    setTimeout(function() {
      player.play();
    }, 100)
  });
}

document.addEventListener("DOMContentLoaded", function(event) {
  document.getElementById('player').onended = function() {
    console.log('boink')
    getSong();
  }
});
