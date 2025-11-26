# Example Tailwind Configuration for ProtoCss

# JIT Mode Configuration
{
  mode: 'jit',  # Use 'jit' for Just-In-Time compilation or 'aot' for Ahead-Of-Time
  
  content: [
    './example/**/*.html',
    './example/**/*.erb',
    './example/**/*.js'
  ],
  
  darkMode: 'class',  # 'media' or 'class'
  
  safelist: [
    'bg-red-500',
    'text-center',
    'hover:bg-blue-600'
  ],
  
  theme: {
    screens: {
      'sm' => '640px',
      'md' => '768px',
      'lg' => '1024px',
      'xl' => '1280px',
      '2xl' => '1536px'
    },
    
    colors: {
      'primary' => '#3b82f6',
      'secondary' => '#8b5cf6',
      'success' => '#10b981',
      'warning' => '#f59e0b',
      'danger' => '#ef4444',
      'white' => '#ffffff',
      'black' => '#000000',
      'gray' => {
        '50' => '#f9fafb',
        '100' => '#f3f4f6',
        '200' => '#e5e7eb',
        '300' => '#d1d5db',
        '400' => '#9ca3af',
        '500' => '#6b7280',
        '600' => '#4b5563',
        '700' => '#374151',
        '800' => '#1f2937',
        '900' => '#111827'
      },
      'blue' => {
        '50' => '#eff6ff',
        '100' => '#dbeafe',
        '200' => '#bfdbfe',
        '300' => '#93c5fd',
        '400' => '#60a5fa',
        '500' => '#3b82f6',
        '600' => '#2563eb',
        '700' => '#1d4ed8',
        '800' => '#1e40af',
        '900' => '#1e3a8a'
      }
    },
    
    spacing: {
      '0' => '0px',
      '1' => '0.25rem',
      '2' => '0.5rem',
      '3' => '0.75rem',
      '4' => '1rem',
      '5' => '1.25rem',
      '6' => '1.5rem',
      '8' => '2rem',
      '10' => '2.5rem',
      '12' => '3rem',
      '16' => '4rem',
      '20' => '5rem',
      '24' => '6rem',
      '32' => '8rem',
      'px' => '1px'
    },
    
    extend: {
      # Add custom theme extensions here
    }
  },
  
  plugins: []
}
