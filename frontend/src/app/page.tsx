'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

export default function Home() {
  const router = useRouter();
  const [description, setDescription] = useState('');

  const examples = [
    'A memecoin for gym bros who love 🐔',
    'A token for people who think pineapple belongs on 🍕',
    'A coin for meme lords who hate Mondays',
  ];

  const handleGenerate = () => {
    if (description.trim()) {
      // Store description and redirect to wizard
      sessionStorage.setItem('memecoinDescription', description);
      router.push('/create');
    }
  };

  const handleExample = (example: string) => {
    setDescription(example);
  };

  return (
    <main className="min-h-screen bg-gradient-to-br from-purple-600 via-purple-700 to-pink-600 flex items-center justify-center p-4">
      <div className="max-w-4xl w-full">
        {/* Hero Section */}
        <div className="text-center mb-12">
          <div className="mb-6">
            <div className="inline-block bg-gradient-to-br from-orange-500 to-red-500 p-4 rounded-2xl shadow-2xl mb-4">
              <span className="text-5xl">🔥</span>
            </div>
          </div>
          <h1 className="text-5xl md:text-6xl font-bold text-white mb-4">
            Forge Your Memecoin with AI
          </h1>
          <p className="text-xl text-purple-100 mb-8">
            Turn your wildest meme ideas into a token with real utility. No coding. No hassle. Just fun.
          </p>
        </div>

        {/* Main CTA Card */}
        <div className="bg-white rounded-3xl shadow-2xl p-8 md:p-12 mb-8">
          <h2 className="text-2xl font-bold text-gray-900 text-center mb-6">
            Describe Your Memecoin
          </h2>
          
          <div className="mb-6">
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Describe your memecoin in one sentence..."
              rows={3}
              className="w-full px-4 py-3 border-2 border-gray-200 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-transparent transition resize-none text-gray-700"
            />
          </div>

          <div className="mb-6">
            <p className="text-sm text-gray-600 mb-2">Need inspiration? Try these:</p>
            <div className="flex flex-wrap gap-2">
              {examples.map((example, index) => (
                <button
                  key={index}
                  onClick={() => handleExample(example)}
                  className="px-3 py-1.5 text-sm bg-gray-100 hover:bg-gray-200 rounded-full transition text-gray-700"
                >
                  {example}
                </button>
              ))}
            </div>
          </div>

          <button
            onClick={handleGenerate}
            disabled={!description.trim()}
            className="w-full bg-gradient-to-r from-purple-600 to-pink-600 text-white font-bold text-lg py-4 px-6 rounded-xl hover:from-purple-700 hover:to-pink-700 transition shadow-lg hover:shadow-xl disabled:opacity-50 disabled:cursor-not-allowed"
          >
            🔥 Generate Memecoin
          </button>
        </div>

        {/* Features */}
        <div className="grid md:grid-cols-3 gap-6 mb-8">
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-6 text-center">
            <div className="text-4xl mb-3">🎨</div>
            <h3 className="text-white font-bold mb-2">AI-Generated Logo</h3>
            <p className="text-purple-100 text-sm">DALL·E 3 creates unique logos for your token</p>
          </div>
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-6 text-center">
            <div className="text-4xl mb-3">💡</div>
            <h3 className="text-white font-bold mb-2">Smart Tokenomics</h3>
            <p className="text-purple-100 text-sm">GPT-4 suggests optimal parameters</p>
          </div>
          <div className="bg-white/10 backdrop-blur-sm rounded-xl p-6 text-center">
            <div className="text-4xl mb-3">🚀</div>
            <h3 className="text-white font-bold mb-2">One-Click Deploy</h3>
            <p className="text-purple-100 text-sm">Deploy to blockchain in seconds</p>
          </div>
        </div>

        {/* Footer */}
        <div className="text-center">
          <p className="text-purple-200 mb-4">MemeForge: Where Memes Meet Utility</p>
          <div className="flex justify-center gap-6 text-purple-200">
            <a href="https://github.com/samuelsmith442/MemeForge" target="_blank" rel="noopener noreferrer" className="hover:text-white transition">
              GitHub
            </a>
            <a href="#" className="hover:text-white transition">Twitter</a>
            <a href="#" className="hover:text-white transition">ETHGlobal</a>
          </div>
        </div>
      </div>
    </main>
  );
}
