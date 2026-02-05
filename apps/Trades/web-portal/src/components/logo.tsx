'use client';

interface LogoProps {
  size?: number;
  className?: string;
  animated?: boolean;
}

export function Logo({ size = 32, className = '', animated = true }: LogoProps) {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 100 100"
      width={size}
      height={size}
      className={className}
    >
      <defs>
        <filter id="glow" x="-50%" y="-50%" width="200%" height="200%">
          <feGaussianBlur stdDeviation="0.4" result="blur" />
          <feMerge>
            <feMergeNode in="blur" />
            <feMergeNode in="SourceGraphic" />
          </feMerge>
        </filter>
      </defs>
      <g transform="translate(50, 50)" filter="url(#glow)">
        {/* Back layer */}
        <path
          d="M-22,-22 L22,-22 L-22,22 L22,22"
          fill="none"
          stroke="currentColor"
          strokeWidth="3"
          strokeLinecap="round"
          strokeLinejoin="round"
          opacity="0.08"
          transform="translate(6,6)"
        >
          {animated && (
            <animate
              attributeName="opacity"
              values="0.08;0.15;0.08"
              dur="2s"
              repeatCount="indefinite"
            />
          )}
        </path>
        {/* Middle layer */}
        <path
          d="M-22,-22 L22,-22 L-22,22 L22,22"
          fill="none"
          stroke="currentColor"
          strokeWidth="3"
          strokeLinecap="round"
          strokeLinejoin="round"
          opacity="0.18"
          transform="translate(3,3)"
        >
          {animated && (
            <animate
              attributeName="opacity"
              values="0.18;0.3;0.18"
              dur="2s"
              repeatCount="indefinite"
              begin="0.3s"
            />
          )}
        </path>
        {/* Front layer */}
        <path
          d="M-22,-22 L22,-22 L-22,22 L22,22"
          fill="none"
          stroke="currentColor"
          strokeWidth="3.5"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          {animated && (
            <animate
              attributeName="stroke-width"
              values="3.5;4;3.5"
              dur="2s"
              repeatCount="indefinite"
              begin="0.6s"
            />
          )}
        </path>
      </g>
    </svg>
  );
}

export function LogoWithText({ size = 32, className = '' }: LogoProps) {
  return (
    <div className={`flex items-center gap-3 ${className}`}>
      <Logo size={size} />
      <span className="text-lg font-semibold text-main">Zafto</span>
    </div>
  );
}
