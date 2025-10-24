'use client';

import { useState } from 'react';

interface ParameterSuggesterProps {
  onSuggestionsGenerated?: (suggestions: any) => void;
  className?: string;
}

interface Suggestions {
  tokenomics: {
    totalSupply: string;
    initialPrice: string;
    maxSupply: string;
  };
  distribution: {
    publicSale: string;
    liquidity: string;
    team: string;
    marketing: string;
    treasury: string;
  };
  staking: {
    minStakePeriod: string;
    maxStakePeriod: string;
    baseAPY: string;
    maxAPY: string;
  };
  governance: {
    proposalThreshold: string;
    votingPeriod: string;
    quorumPercentage: string;
  };
  reasoning: {
    tokenomics: string;
    distribution: string;
    staking: string;
    governance: string;
  };
  recommendations: string[];
}

export default function ParameterSuggester({ onSuggestionsGenerated, className = '' }: ParameterSuggesterProps) {
  const [name, setName] = useState('');
  const [theme, setTheme] = useState('');
  const [targetAudience, setTargetAudience] = useState('');
  const [goals, setGoals] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [suggestions, setSuggestions] = useState<Suggestions | null>(null);

  const themes = [
    { value: 'space', label: '🚀 Space & Cosmos' },
    { value: 'gaming', label: '🎮 Gaming' },
    { value: 'meme', label: '😂 Classic Meme' },
    { value: 'animal', label: '🐕 Animals' },
    { value: 'food', label: '🍕 Food & Drinks' },
    { value: 'tech', label: '💻 Technology' },
    { value: 'nature', label: '🌿 Nature' },
    { value: 'fantasy', label: '🧙 Fantasy' },
  ];

  const handleGenerate = async () => {
    if (!name || !theme) {
      setError('Please fill in name and theme');
      return;
    }

    setLoading(true);
    setError('');
    setSuggestions(null);

    try {
      const response = await fetch('/api/ai/suggest-params', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, theme, targetAudience, goals }),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.message || 'Failed to generate suggestions');
      }

      setSuggestions(data.suggestions);

      if (onSuggestionsGenerated) {
        onSuggestionsGenerated(data.suggestions);
      }
    } catch (err: any) {
      setError(err.message || 'An error occurred');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className={`bg-white rounded-xl shadow-lg p-6 ${className}`}>
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-900 mb-2">💡 Parameter Suggestions</h2>
        <p className="text-gray-600">Get AI-powered tokenomics recommendations</p>
      </div>

      {/* Input Form */}
      <div className="space-y-4 mb-6">
        {/* Name Input */}
        <div>
          <label htmlFor="param-name" className="block text-sm font-semibold text-gray-700 mb-2">
            Memecoin Name *
          </label>
          <input
            id="param-name"
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
          <label htmlFor="param-theme" className="block text-sm font-semibold text-gray-700 mb-2">
            Theme *
          </label>
          <select
            id="param-theme"
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

        {/* Target Audience */}
        <div>
          <label htmlFor="audience" className="block text-sm font-semibold text-gray-700 mb-2">
            Target Audience (Optional)
          </label>
          <input
            id="audience"
            type="text"
            value={targetAudience}
            onChange={(e) => setTargetAudience(e.target.value)}
            placeholder="e.g., gamers and crypto enthusiasts"
            className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition"
            disabled={loading}
          />
        </div>

        {/* Goals */}
        <div>
          <label htmlFor="goals" className="block text-sm font-semibold text-gray-700 mb-2">
            Goals (Optional)
          </label>
          <textarea
            id="goals"
            value={goals}
            onChange={(e) => setGoals(e.target.value)}
            placeholder="e.g., build strong community, enable governance, reward long-term holders"
            rows={3}
            className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition resize-none"
            disabled={loading}
          />
        </div>

        {/* Generate Button */}
        <button
          onClick={handleGenerate}
          disabled={loading || !name || !theme}
          className="w-full bg-gradient-to-r from-purple-600 to-pink-600 text-white font-semibold py-4 px-6 rounded-lg hover:from-purple-700 hover:to-pink-700 transition disabled:opacity-50 disabled:cursor-not-allowed shadow-lg hover:shadow-xl"
        >
          {loading ? (
            <span className="flex items-center justify-center">
              <svg className="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
              Generating Suggestions... (15 seconds)
            </span>
          ) : (
            '✨ Generate Suggestions'
          )}
        </button>
      </div>

      {/* Error Message */}
      {error && (
        <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-lg">
          <p className="text-red-800 text-sm font-medium">❌ {error}</p>
        </div>
      )}

      {/* Results Display */}
      {suggestions && (
        <div className="border-t pt-6 space-y-6">
          <h3 className="text-lg font-bold text-gray-900">✅ Suggestions Generated!</h3>

          {/* Tokenomics */}
          <div className="bg-gradient-to-br from-blue-50 to-indigo-50 p-5 rounded-lg border border-blue-200">
            <h4 className="text-lg font-bold text-blue-900 mb-3 flex items-center">
              <span className="mr-2">📊</span> Tokenomics
            </h4>
            <div className="space-y-2">
              <div className="flex justify-between items-center bg-white px-4 py-2 rounded">
                <span className="font-medium text-gray-700">Total Supply:</span>
                <span className="font-bold text-blue-600">{suggestions.tokenomics.totalSupply}</span>
              </div>
              <div className="flex justify-between items-center bg-white px-4 py-2 rounded">
                <span className="font-medium text-gray-700">Initial Price:</span>
                <span className="font-bold text-blue-600">${suggestions.tokenomics.initialPrice}</span>
              </div>
              <div className="flex justify-between items-center bg-white px-4 py-2 rounded">
                <span className="font-medium text-gray-700">Max Supply:</span>
                <span className="font-bold text-blue-600">{suggestions.tokenomics.maxSupply}</span>
              </div>
            </div>
            <div className="mt-3 p-3 bg-blue-100 rounded text-sm text-blue-800">
              <strong>Reasoning:</strong> {suggestions.reasoning.tokenomics}
            </div>
          </div>

          {/* Distribution */}
          <div className="bg-gradient-to-br from-green-50 to-emerald-50 p-5 rounded-lg border border-green-200">
            <h4 className="text-lg font-bold text-green-900 mb-3 flex items-center">
              <span className="mr-2">📈</span> Distribution
            </h4>
            <div className="space-y-2">
              <div className="flex justify-between items-center bg-white px-4 py-2 rounded">
                <span className="font-medium text-gray-700">Public Sale:</span>
                <span className="font-bold text-green-600">{suggestions.distribution.publicSale}</span>
              </div>
              <div className="flex justify-between items-center bg-white px-4 py-2 rounded">
                <span className="font-medium text-gray-700">Liquidity:</span>
                <span className="font-bold text-green-600">{suggestions.distribution.liquidity}</span>
              </div>
              <div className="flex justify-between items-center bg-white px-4 py-2 rounded">
                <span className="font-medium text-gray-700">Team:</span>
                <span className="font-bold text-green-600">{suggestions.distribution.team}</span>
              </div>
              <div className="flex justify-between items-center bg-white px-4 py-2 rounded">
                <span className="font-medium text-gray-700">Marketing:</span>
                <span className="font-bold text-green-600">{suggestions.distribution.marketing}</span>
              </div>
              <div className="flex justify-between items-center bg-white px-4 py-2 rounded">
                <span className="font-medium text-gray-700">Treasury:</span>
                <span className="font-bold text-green-600">{suggestions.distribution.treasury}</span>
              </div>
            </div>
            <div className="mt-3 p-3 bg-green-100 rounded text-sm text-green-800">
              <strong>Reasoning:</strong> {suggestions.reasoning.distribution}
            </div>
          </div>

          {/* Staking */}
          <div className="bg-gradient-to-br from-purple-50 to-pink-50 p-5 rounded-lg border border-purple-200">
            <h4 className="text-lg font-bold text-purple-900 mb-3 flex items-center">
              <span className="mr-2">🔒</span> Staking
            </h4>
            <div className="space-y-2">
              <div className="flex justify-between items-center bg-white px-4 py-2 rounded">
                <span className="font-medium text-gray-700">Min Stake Period:</span>
                <span className="font-bold text-purple-600">{suggestions.staking.minStakePeriod} days</span>
              </div>
              <div className="flex justify-between items-center bg-white px-4 py-2 rounded">
                <span className="font-medium text-gray-700">Max Stake Period:</span>
                <span className="font-bold text-purple-600">{suggestions.staking.maxStakePeriod} days</span>
              </div>
              <div className="flex justify-between items-center bg-white px-4 py-2 rounded">
                <span className="font-medium text-gray-700">Base APY:</span>
                <span className="font-bold text-purple-600">{suggestions.staking.baseAPY}</span>
              </div>
              <div className="flex justify-between items-center bg-white px-4 py-2 rounded">
                <span className="font-medium text-gray-700">Max APY:</span>
                <span className="font-bold text-purple-600">{suggestions.staking.maxAPY}</span>
              </div>
            </div>
            <div className="mt-3 p-3 bg-purple-100 rounded text-sm text-purple-800">
              <strong>Reasoning:</strong> {suggestions.reasoning.staking}
            </div>
          </div>

          {/* Governance */}
          <div className="bg-gradient-to-br from-orange-50 to-amber-50 p-5 rounded-lg border border-orange-200">
            <h4 className="text-lg font-bold text-orange-900 mb-3 flex items-center">
              <span className="mr-2">🗳️</span> Governance
            </h4>
            <div className="space-y-2">
              <div className="flex justify-between items-center bg-white px-4 py-2 rounded">
                <span className="font-medium text-gray-700">Proposal Threshold:</span>
                <span className="font-bold text-orange-600">{suggestions.governance.proposalThreshold} tokens</span>
              </div>
              <div className="flex justify-between items-center bg-white px-4 py-2 rounded">
                <span className="font-medium text-gray-700">Voting Period:</span>
                <span className="font-bold text-orange-600">{suggestions.governance.votingPeriod} days</span>
              </div>
              <div className="flex justify-between items-center bg-white px-4 py-2 rounded">
                <span className="font-medium text-gray-700">Quorum:</span>
                <span className="font-bold text-orange-600">{suggestions.governance.quorumPercentage}</span>
              </div>
            </div>
            <div className="mt-3 p-3 bg-orange-100 rounded text-sm text-orange-800">
              <strong>Reasoning:</strong> {suggestions.reasoning.governance}
            </div>
          </div>

          {/* Recommendations */}
          <div className="bg-gradient-to-br from-cyan-50 to-sky-50 p-5 rounded-lg border border-cyan-200">
            <h4 className="text-lg font-bold text-cyan-900 mb-3 flex items-center">
              <span className="mr-2">💡</span> Key Recommendations
            </h4>
            <ul className="space-y-2">
              {suggestions.recommendations.map((rec, index) => (
                <li key={index} className="flex items-start bg-white p-3 rounded">
                  <span className="text-cyan-600 font-bold mr-3">{index + 1}.</span>
                  <span className="text-gray-700">{rec}</span>
                </li>
              ))}
            </ul>
          </div>
        </div>
      )}
    </div>
  );
}
