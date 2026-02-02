export default function TestStyling() {
  return (
    <div className="p-8 space-y-8">
      <h1 className="text-4xl font-bold text-slate-900">Styling Test Page</h1>

      {/* Test gradient background */}
      <div className="bg-gradient-to-r from-blue-500 to-indigo-600 text-white p-6 rounded-xl">
        <h2 className="text-xl font-semibold">Gradient Test</h2>
        <p>This should have a blue to indigo gradient background.</p>
      </div>

      {/* Test glassmorphism effect */}
      <div className="bg-white/80 backdrop-blur-sm border border-white/20 p-6 rounded-xl shadow-lg">
        <h2 className="text-xl font-semibold text-slate-900">
          Glassmorphism Test
        </h2>
        <p className="text-slate-600">
          This should have a glass-like effect with backdrop blur.
        </p>
      </div>

      {/* Test hover effects */}
      <div className="bg-white p-6 rounded-xl shadow-lg hover:shadow-xl hover:-translate-y-1 transition-all duration-300 cursor-pointer">
        <h2 className="text-xl font-semibold text-slate-900">
          Hover Effect Test
        </h2>
        <p className="text-slate-600">
          This should lift up and get more shadow on hover.
        </p>
      </div>

      {/* Test animations */}
      <div className="bg-slate-900 text-white p-6 rounded-xl">
        <div className="flex items-center space-x-4">
          <div className="w-4 h-4 bg-green-400 rounded-full animate-pulse"></div>
          <span>Animated pulse indicator</span>
        </div>
      </div>

      {/* Test modern card layout */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {[1, 2, 3].map(i => (
          <div
            key={i}
            className="bg-white/90 backdrop-blur-sm rounded-xl p-6 shadow-lg border border-white/20"
          >
            <h3 className="text-lg font-semibold text-slate-900 mb-2">
              Card {i}
            </h3>
            <p className="text-slate-600">
              Modern card with glassmorphism effect.
            </p>
          </div>
        ))}
      </div>
    </div>
  );
}
