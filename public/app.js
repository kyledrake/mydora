function getSong() {
  var request = new XMLHttpRequest();
  request.open('GET', '/song.json', true);

  request.onload = function() {
    if (request.status >= 200 && request.status < 400) {
      var data = JSON.parse(request.responseText);

      console.log(data)

      var song_artist = data.artist.name+' - '+data.song.name;

      if(data.artist.genres) {
        data.artist.genres.replace(/,/g, ', ');
      } else {
        data.artist.genres = ''
      }

      document.getElementById('control_panel').style.display = 'block';

      var player = document.getElementById('player');
      var history = document.getElementById('history');
      var history_cover = document.getElementById('history_cover');

      document.getElementById('play_button').innerText = 'Next Song'

      document.getElementById("song_info").innerText = song_artist;
      document.getElementById('genres').innerText = data.artist.genres;
      history.innerHTML = song_artist+'<br>'+document.getElementById('history').innerHTML;
      history_cover.style.display = 'block';
      document.getElementById("player_source").src = '/songs'+data.song.path;
      player.style.display = 'block';
      player.load();

      setTimeout(function() {
        player.play();
      }, 100)

    } else {
      // We reached our target server, but it returned an error
    }
  };

  request.onerror = function() {
    // There was a connection error of some sort
  };

  request.send();
}

document.addEventListener("DOMContentLoaded", function(event) {
  document.getElementById('player').onended = function() {
    console.log('boink')
    getSong();
  }
});
