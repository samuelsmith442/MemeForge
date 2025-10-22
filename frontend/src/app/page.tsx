export default function Home() {
  return (
    <main className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100">
      <div className="text-center p-8 bg-white rounded-2xl shadow-xl max-w-2xl">
        <h1 className="text-5xl font-bold text-gray-900 mb-4">
          🔥 MemeForge
        </h1>
        <p className="text-xl text-gray-600 mb-8">
          AI-Powered Memecoin Creation Platform
        </p>
        
        <div className="space-y-4 text-left">
          <div className="p-4 bg-green-50 rounded-lg border border-green-200">
            <h3 className="font-semibold text-green-900 mb-2">✅ API Status</h3>
            <ul className="text-sm text-green-700 space-y-1">
              <li>• OpenAI: Connected</li>
              <li>• Pinata: Connected</li>
              <li>• Logo Generation: Ready</li>
            </ul>
          </div>

          <div className="p-4 bg-blue-50 rounded-lg border border-blue-200">
            <h3 className="font-semibold text-blue-900 mb-2">🚀 Available Endpoints</h3>
            <ul className="text-sm text-blue-700 space-y-1">
              <li>• <code className="bg-blue-100 px-2 py-1 rounded">/api/ai/generate-logo</code></li>
            </ul>
          </div>

          <div className="p-4 bg-purple-50 rounded-lg border border-purple-200">
            <h3 className="font-semibold text-purple-900 mb-2">🧪 Test the API</h3>
            <p className="text-sm text-purple-700 mb-2">
              Open <code className="bg-purple-100 px-2 py-1 rounded">test-logo-api.html</code> to test logo generation
            </p>
            <p className="text-xs text-purple-600">
              Or use curl: <code className="bg-purple-100 px-1 rounded text-xs">curl -X POST http://localhost:3000/api/ai/generate-logo ...</code>
            </p>
          </div>
        </div>

        <div className="mt-8 pt-6 border-t border-gray-200">
          <p className="text-sm text-gray-500">
            Next.js 15 • OpenAI • Pinata • Web3
          </p>
        </div>
      </div>
    </main>
  );
}
