import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { Typography, Box } from '@mui/material';
import { Line } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js';

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend
);

export const options = {
  responsive: true,
  plugins: {
    legend: {
      position: 'top',
    },
    title: {
      display: true,
    },
    scales: {
      x: {
        type: "timeseries",
        time: {
          parser: 'MM/DD/YYYY HH:mm',
          tooltipFormat: 'll HH:mm',
          unit: 'day',
          unitStepSize: 1,
          displayFormats: {
            'day': 'MM/DD/YYYY'
          }
        },
        title: {
          display: true,
        },
        ticks: {
          // maxTicksLimit: 10,
          autoSkip: true,
          source: "labels",
          callback: function (tick, index, array) {
            return index % 2 ? "" : tick;
          },
          count: 10,
          minRotation: 0,
          maxRotation: 45,
        },
      },
    },
  },
};

const CpuMetrics = () => {
  // eslint-disable-next-line no-unused-vars
  const [cpuMetrics, setCpuMetrics] = useState([]);

  useEffect(() => {
    const response = axios.get('/api/cpu-metrics').then((response) => {
      setCpuMetrics(response.data);
    });
    console.log(response);

  }, []);

  // const cpuObject = Object.entries(cpuMetrics)
  // const data = {
  //   labels: cpuObject.length > 0 ? cpuObject[0][1]?.timestamps : [],
  //   datasets: [
  //     {
  //       label: cpuObject.length > 0 ? cpuObject[0][0] : 'CPU',
  //       data: cpuObject.length > 0 ? cpuObject[0][1]?.metrics : [],
  //       fill: false,
  //       backgroundColor: 'rgba(75,192,192,0.4)',
  //       borderColor: 'rgba(75,192,192,1)',
  //     },
  //   ],
  // };

  const timestamps = ["2023-05-05T08:58:21", "2023-05-05T09:58:21", "2023-05-05T10:58:21", "2023-05-05T11:58:21", "2023-05-05T12:58:21", "2023-05-05T13:58:21", "2023-05-05T14:58:21", "2023-05-05T15:58:21", "2023-05-05T16:58:21", "2023-05-05T17:58:21"]
  const metrics = [0.63, 2.59, 0.6, 1.6, 0.58, 3.61, 4.62, 0.63, 0.62, 3.04]

  const data = {
    labels: timestamps,
    datasets: [
      {
        label: 'CPU %',
        data: metrics,
        fill: false,
        backgroundColor: 'rgba(75,192,192,0.4)',
        borderColor: 'rgba(75,192,192,1)',
      },
    ],
  };

  return (

    <Box sx={{ display: 'flex', justifyItems: 'center', width: '50%', height: '800px' }}>
      <Typography>CPU Metrics</Typography>
      <Line data={data} options={options} />
    </Box>
  )
};

export default CpuMetrics;
