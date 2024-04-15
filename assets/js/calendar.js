var $ = window.$;

$('.calendar-list li').click(function() {
  var card = $(this).children('.calendar-card');
  $('.calendar-card').not(card).slideUp(500);

  card.slideDown(500);
});

(() => {
  const application = Stimulus.Application.start()

  application.register("calendar", class extends Stimulus.Controller {
    static targets = [ "localtz" ];
    connect(){
      let tz_description = Intl.DateTimeFormat().resolvedOptions().timeZone;
      this.localtzTarget.innerHTML = `<b>now localized for ${tz_description}</b>`;
    }
  })

  application.register("calrow", class extends Stimulus.Controller {
    static targets = [ "timestamp", "time", "date" ];
    connect(){

      if(this.hasTimestampTarget && this.hasDateTarget && this.hasTimeTarget) {
        let ts = Date.parse(this.timestampTarget.innerHTML);
        let dto = new Date(ts);
        let locale = navigator.language;
        // let locale = 'en-UK';

        // Set date string 
        let dt_string = dto.toLocaleDateString(locale, {
          month: 'numeric', day: 'numeric', year: 'numeric',
          timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone
        }); // .replace(/\//g, '-');
        this.dateTarget.innerHTML = dt_string;

        let tm_string = dto.toLocaleTimeString(locale, {
          hour: '2-digit',
          minute: '2-digit',
          timeZoneName: 'short'
        });
        this.timeTarget.innerHTML = tm_string;
      }
    }
  })
})()
