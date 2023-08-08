$(document).on('turbolinks:load', function() {
  const ctx = document.getElementById('report');

  if (ctx == null) {
    return
  };

  const apiUrl = '/api/v1/admin/reports/' + ctx.dataset.report;

  async function fetchData(url) {
    let req = await fetch(url);
    let json = await req.json();

    return json;
  }

  async function prepareCameras(data) {
    new Chart(
      ctx,
      {
        type: 'pie',
        options: {
          plugins: {
            legend: {
                display: true,
                position: 'right'
            }
          }
        },
        data: {
          labels: data.map(x => x.camera),
          datasets: [
            {
              label: 'Кол-во фото',
              data: data.map(row => row.count)
            }
          ]
        }
      }
    )
  };

  async function prepareActivities(data) {
    new Chart(
      ctx,
      {
        type: 'bar',
        options: {
          responsive: true
        },
        data: {
          labels: data.map(x => x.month),
          datasets: [
            {
              label: 'Кол-во фото в месяце',
              data: data.map(row => row.count)
            }
          ]
        }
      }
    )
  };

  fetchData(apiUrl).then(data => {
    switch(ctx.dataset.report) {
      case 'cameras':
        prepareCameras(data);
        break;
      case 'activities':
        prepareActivities(data);
        break;
      default:
        alert('wrong report!');
    }
  });
});
