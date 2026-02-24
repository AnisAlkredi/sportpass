export default function LineIcon({ name }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.8"
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      focusable="false"
    >
      {name === "noFee" && (
        <>
          <circle cx="12" cy="12" r="9" />
          <path d="m5 5 14 14" />
          <path d="M9 10h6a2 2 0 1 1 0 4H9" />
          <path d="M12 8v8" />
        </>
      )}

      {name === "extraTraffic" && (
        <>
          <circle cx="10" cy="8" r="3" />
          <path d="M4 19a6 6 0 0 1 12 0" />
          <path d="M18 8v4" />
          <path d="M16 10h4" />
        </>
      )}

      {name === "qr" && (
        <>
          <rect x="3" y="3" width="7" height="7" rx="1" />
          <rect x="14" y="3" width="7" height="7" rx="1" />
          <rect x="3" y="14" width="7" height="7" rx="1" />
          <rect x="14" y="14" width="3" height="3" rx="0.6" />
          <path d="M21 14v7h-4" />
          <path d="M18 18h3" />
        </>
      )}

      {name === "transparency" && (
        <>
          <path d="M12 3 5 6v5c0 5 3.5 8.5 7 10 3.5-1.5 7-5 7-10V6l-7-3z" />
          <path d="m9 12 2 2 4-4" />
        </>
      )}

      {name === "dashboard" && (
        <>
          <path d="M4 19h16" />
          <rect x="6" y="11" width="3" height="6" rx="0.8" />
          <rect x="11" y="8" width="3" height="9" rx="0.8" />
          <rect x="16" y="5" width="3" height="12" rx="0.8" />
        </>
      )}

      {name === "localMarket" && (
        <>
          <path d="M9 4 3 6v14l6-2 6 2 6-2V4l-6 2-6-2z" />
          <path d="M9 4v14" />
          <path d="M15 6v14" />
        </>
      )}

      {name === "register" && (
        <>
          <rect x="6" y="4" width="12" height="16" rx="2" />
          <path d="M9 4h6a1 1 0 0 0 0-2H9a1 1 0 0 0 0 2z" />
          <path d="M9 10h6" />
          <path d="M9 14h4" />
        </>
      )}

      {name === "pricing" && (
        <>
          <ellipse cx="12" cy="6" rx="6" ry="3" />
          <path d="M6 6v8c0 1.7 2.7 3 6 3s6-1.3 6-3V6" />
          <path d="M6 10c0 1.7 2.7 3 6 3s6-1.3 6-3" />
        </>
      )}

      {name === "scan" && (
        <>
          <path d="M4 7V5a1 1 0 0 1 1-1h2" />
          <path d="M20 7V5a1 1 0 0 0-1-1h-2" />
          <path d="M4 17v2a1 1 0 0 0 1 1h2" />
          <path d="M20 17v2a1 1 0 0 1-1 1h-2" />
          <path d="M7 12h10" />
          <path d="M9 9h6" />
          <path d="M9 15h6" />
        </>
      )}
    </svg>
  );
}
