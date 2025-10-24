'use client';

import { useState } from 'react';
import Image from 'next/image';

interface LogoGeneratorProps {
  onLogoGenerated?: (imageUrl: string, prompt: string) => void;
  className?: string;
}

export default function LogoGenerator({ onLogoGenerated, className = '' }: LogoGeneratorProps) {
  const [name, setName] = useState('');
  const [theme, setTheme] = useState('');
  const [style, setStyle] = useState('');
  const [additionalPrompt, setAdditionalPrompt] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [result, setResult] = useState<{
    imageUrl: string;
    prompt: string;
    revisedPrompt: string;
  } | null>(null);

  const themes = [
    { value: 'space', label: '🚀 Space & Cosmos', emoji: '🚀' },
    { value: 'gaming', label: '🎮 Gaming', emoji: '🎮' },
    { value: 'meme', label: '😂 Classic Meme', emoji: '😂' },
    { value: 'animal', label: '🐕 Animals', emoji: '🐕' },
    { value: 'food', label: '🍕 Food & Drinks', emoji: '🍕' },
    { value: 'tech', label: '💻 Technology', emoji: '💻' },
    { value: 'nature', label: '🌿 Nature', emoji: '🌿' },
    { value: 'fantasy', label: '🧙 Fantasy', emoji: '🧙' },
  ];

  const styles = [
    { value: 'cartoon', label: 'Cartoon' },
    { value: 'minimalist', label: 'Minimalist' },
    { value: '3d', label: '3D' },
    { value: 'pixel-art', label: 'Pixel Art' },
    { value: 'abstract', label: 'Abstract' },
    { value: 'realistic', label: 'Realistic' },
  ];

  const handleGenerate = async () => {
    if (!name || !theme || !style) {
      setError('Please fill in all required fields');
      return;
    }

    setLoading(true);
    setError('');
    setResult(null);

    try {
      const response = await fetch('/api/ai/generate-logo', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, theme, style, additionalPrompt }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.message || 'Failed to generate logo');
      }

      setResult({
        imageUrl: data.imageUrl,
        prompt: data.prompt,
        revisedPrompt: data.revisedPrompt,
      });

      if (onLogoGenerated) {
        onLogoGenerated(data.imageUrl, data.prompt);
      }
    } catch (err: any) {
      setError(err.message || 'An error occurred');
    } finally {
      setLoading(false);
    }
  };

  const handleDownload = () => {
    if (result?.imageUrl) {
      const link = document.createElement('a');
      link.href = result.imageUrl;
      link.download = `${name}-logo.png`;
      link.click();
    }
  };

  return (
    <div className={`bg-white rounded-xl shadow-lg p-6 ${className}`}>
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 mb-2">🎨 AI Logo Generator</h2>
        <p className="text-gray-600">Create a unique logo for your memecoin using AI</p>
      </div>

      {/* Input Form */}
      <div className="space-y-4 mb-6">
        {/* Name Input */}
        <div>
          <label htmlFor="name" className="block text-sm font-semibold text-gray-700 mb-2">
            Memecoin Name *
          </label>
          <input
            id="name"
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="e.g., MoonDoge"
            className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition"
            disabled={loading}
          />
        </div>

        {/* Theme Selection */}
        <div>
          <label htmlFor="theme" className="block text-sm font-semibold text-gray-700 mb-2">
            Theme *
          </label>
          <select
            id="theme"
            value={theme}
            onChange={(e) => setTheme(e.target.value)}
            className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition"
            disabled={loading}
          >
            <option value="">Select a theme...</option>
            {themes.map((t) => (
              <option key={t.value} value={t.value}>
                {t.label}
              </option>
            ))}
          </select>
        </div>

        {/* Style Selection */}
        <div>
          <label htmlFor="style" className="block text-sm font-semibold text-gray-700 mb-2">
            Style *
          </label>
          <div className="grid grid-cols-2 md:grid-cols-3 gap-2">
            {styles.map((s) => (
              <button
                key={s.value}
                onClick={() => setStyle(s.value)}
                disabled={loading}
                className={`px-4 py-3 rounded-lg border-2 transition font-medium ${
                  style === s.value
                    ? 'border-blue-500 bg-blue-50 text-blue-700'
                    : 'border-gray-300 bg-white text-gray-700 hover:border-gray-400'
                } disabled:opacity-50 disabled:cursor-not-allowed`}
              >
                {s.label}
              </button>
            ))}
          </div>
        </div>

        {/* Additional Prompt */}
        <div>
          <label htmlFor="additional" className="block text-sm font-semibold text-gray-700 mb-2">
            Additional Details (Optional)
          </label>
          <textarea
            id="additional"
            value={additionalPrompt}
            onChange={(e) => setAdditionalPrompt(e.target.value)}
            placeholder="e.g., Make it colorful and fun"
            rows={3}
            className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition resize-none"
            disabled={loading}
          />
        </div>

        {/* Generate Button */}
        <button
          onClick={handleGenerate}
          disabled={loading || !name || !theme || !style}
          className="w-full bg-gradient-to-r from-blue-600 to-indigo-600 text-white font-semibold py-4 px-6 rounded-lg hover:from-blue-700 hover:to-indigo-700 transition disabled:opacity-50 disabled:cursor-not-allowed shadow-lg hover:shadow-xl"
        >
          {loading ? (
            <span className="flex items-center justify-center">
              <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Generating Logo... (30 seconds)
            </span>
          ) : (
            '✨ Generate Logo'
          )}
        </button>
      </div>

      {/* Error Message */}
      {error && (
        <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg">
          <p className="text-red-800 text-sm font-medium">❌ {error}</p>
        </div>
      )}

      {/* Result Display */}
      {result && (
        <div className="border-t pt-6">
          <h3 className="text-lg font-bold text-gray-900 mb-4">✅ Logo Generated!</h3>
          
          {/* Logo Image */}
          <div className="mb-4 relative aspect-square w-full max-w-md mx-auto bg-gray-100 rounded-lg overflow-hidden">
            <Image
              src={result.imageUrl}
              alt={`${name} logo`}
              fill
              className="object-contain"
              unoptimized
            />
          </div>

          {/* Download Button */}
          <button
            onClick={handleDownload}
            className="w-full mb-4 bg-green-600 text-white font-semibold py-3 px-6 rounded-lg hover:bg-green-700 transition shadow-md hover:shadow-lg"
          >
            ⬇️ Download Logo
          </button>

          {/* Prompts */}
          <div className="space-y-3">
            <div className="bg-gray-50 p-4 rounded-lg">
              <h4 className="text-sm font-semibold text-gray-700 mb-2">Your Prompt:</h4>
              <p className="text-sm text-gray-600">{result.prompt}</p>
            </div>
            <div className="bg-blue-50 p-4 rounded-lg">
              <h4 className="text-sm font-semibold text-blue-700 mb-2">AI-Enhanced Prompt:</h4>
              <p className="text-sm text-blue-600">{result.revisedPrompt}</p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
