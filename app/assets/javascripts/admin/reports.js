$(document).on('turbolinks:load', function() {
  const ctx = document.getElementById('report');

  if (ctx == null) {
    return
  };

  const apiUrl = '/api/v1/admin/reports/cameras';

  async function fetchCameras(url) {
    let req = await fetch(url);
    let json = await req.json();

    return json;
  }

  async function prepareChart(cameras) {
    new Chart(
      document.getElementById('report'),
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
          labels: cameras.map(x => x.camera),
          datasets: [
            {
              label: 'Кол-во фото',
              data: cameras.map(row => row.count)
            }
          ]
        }
      }
    )
  };

  fetchCameras(apiUrl).then(list => {
    prepareChart(list);
  });
});
