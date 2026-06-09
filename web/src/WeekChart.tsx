import { type Day } from './api';
export function WeekChart({ days }: { days: Day[] }) {
  const points = days.map((day, index) => ({
    ...day,
    x: 40 + index * 112,
    y: day.average === null ? null : 276 - (day.average - 1) * 60,
  }));
  let drawing = false;
  const path = points
    .map((point) => {
      if (point.y === null) {
        drawing = false;
        return '';
      }
      const command = drawing ? 'L' : 'M';
      drawing = true;
      return `${command}${point.x},${point.y}`;
    })
    .join(' ');
  const areas: string[] = [];
  let segment: typeof points = [];
  for (const point of [...points, { day: '', average: null, count: 0, x: 0, y: null }]) {
    if (point.y !== null) segment.push(point);
    else if (segment.length) {
      areas.push(
        `M${segment[0].x},276 ${segment.map((p) => `L${p.x},${p.y}`).join(' ')} L${segment.at(-1)!.x},276 Z`,
      );
      segment = [];
    }
  }
  return (
    <section className="week panel">
      <h2>Your week</h2>
      {days.some((day) => day.count > 0) ? (
        <svg
          className="chart"
          viewBox="0 0 750 310"
          role="img"
          aria-label="Average mood by day over the last seven days. Scale from one to five."
        >
          <defs>
            <linearGradient id="mood-area" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#21624c" stopOpacity=".16" />
              <stop offset="100%" stopColor="#21624c" stopOpacity="0" />
            </linearGradient>
          </defs>
          {areas.map((area, index) => (
            <path key={index} d={area} fill="url(#mood-area)" />
          ))}
          {[1, 2, 3, 4, 5].map((value) => (
            <g key={value}>
              <line
                x1="40"
                x2="735"
                y1={276 - (value - 1) * 60}
                y2={276 - (value - 1) * 60}
                stroke="#dce5de"
              />
              <text x="15" y={282 - (value - 1) * 60}>
                {value}
              </text>
            </g>
          ))}
          <path d={path} fill="none" stroke="#21624c" strokeWidth="2.5" />
          {points.map((point, index) => (
            <g key={point.day}>
              {point.y !== null ? (
                <circle cx={point.x} cy={point.y} r="5" fill="#21624c">
                  <title>
                    {point.day}: {point.average} from {point.count} check ins
                  </title>
                </circle>
              ) : null}
              <text x={point.x} y="306" textAnchor="middle">
                {index === 6
                  ? 'Today'
                  : new Date(`${point.day}T12:00:00`).toLocaleDateString(undefined, {
                      weekday: 'short',
                    })}
              </text>
            </g>
          ))}
        </svg>
      ) : (
        <div className="chart-empty">
          <span className="empty-leaf" aria-hidden="true">
            ⌁
          </span>
          <p>Your week begins with one check in.</p>
          <span>There is no right way to feel.</span>
        </div>
      )}
      <p className="hint">Your entries stay private to your account.</p>
      <table className="sr-only">
        <caption>Weekly mood averages</caption>
        <thead>
          <tr>
            <th>Date</th>
            <th>Average</th>
            <th>Entries</th>
          </tr>
        </thead>
        <tbody>
          {days.map((day) => (
            <tr key={day.day}>
              <td>{day.day}</td>
              <td>{day.average ?? 'No entry'}</td>
              <td>{day.count}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </section>
  );
}
