'use client';

import { useState } from 'react';
import LogoGenerator from '../ai/LogoGenerator';
import ParameterSuggester from '../ai/ParameterSuggester';
import AIChat from '../ai/AIChat';

interface WizardData {
  name: string;
  theme: string;
  logoUrl?: string;
  logoPrompt?: string;
  suggestions?: any;
}

export default function CreationWizard() {
  const [currentStep, setCurrentStep] = useState(1);
  const [wizardData, setWizardData] = useState<WizardData>({
    name: '',
    theme: '',
  });

  const steps = [
    { number: 1, title: 'Basic Info', icon: '📝' },
    { number: 2, title: 'Generate Logo', icon: '🎨' },
    { number: 3, title: 'Parameters', icon: '💡' },
    { number: 4, title: 'Review', icon: '✅' },
  ];

  const handleLogoGenerated = (imageUrl: string, prompt: string) => {
    setWizardData((prev) => ({
      ...prev,
      logoUrl: imageUrl,
      logoPrompt: prompt,
    }));
  };

  const handleSuggestionsGenerated = (suggestions: any) => {
    setWizardData((prev) => ({
      ...prev,
      suggestions,
    }));
  };

  const canProceed = (step: number) => {
    switch (step) {
      case 1:
        return wizardData.name && wizardData.theme;
      case 2:
        return wizardData.logoUrl;
      case 3:
        return wizardData.suggestions;
      default:
        return true;
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-indigo-50 to-purple-50 py-12 px-4">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-4xl md:text-5xl font-bold text-gray-900 mb-4">
            🚀 Create Your Memecoin
          </h1>
          <p className="text-lg text-gray-600">
            AI-powered memecoin creation in 4 simple steps
          </p>
        </div>

        {/* Progress Steps */}
        <div className="mb-12">
          <div className="flex items-center justify-between max-w-3xl mx-auto">
            {steps.map((step, index) => (
              <div key={step.number} className="flex items-center flex-1">
                {/* Step Circle */}
                <div className="flex flex-col items-center">
                  <button
                    onClick={() => setCurrentStep(step.number)}
                    disabled={step.number > currentStep && !canProceed(step.number - 1)}
                    className={`w-16 h-16 rounded-full flex items-center justify-center text-2xl font-bold transition-all ${
                      currentStep === step.number
                        ? 'bg-blue-600 text-white shadow-lg scale-110'
                        : currentStep > step.number
                        ? 'bg-green-500 text-white'
                        : 'bg-gray-200 text-gray-400'
                    } disabled:cursor-not-allowed`}
                  >
                    {currentStep > step.number ? '✓' : step.icon}
                  </button>
                  <span className="mt-2 text-sm font-medium text-gray-700 text-center">
                    {step.title}
                  </span>
                </div>

                {/* Connector Line */}
                {index < steps.length - 1 && (
                  <div
                    className={`flex-1 h-1 mx-4 transition-all ${
                      currentStep > step.number ? 'bg-green-500' : 'bg-gray-200'
                    }`}
                  />
                )}
              </div>
            ))}
          </div>
        </div>

        {/* Step Content */}
        <div className="bg-white rounded-2xl shadow-2xl p-8">
          {/* Step 1: Basic Info */}
          {currentStep === 1 && (
            <div className="space-y-6">
              <div>
                <h2 className="text-2xl font-bold text-gray-900 mb-2">📝 Basic Information</h2>
                <p className="text-gray-600">Let's start with the basics of your memecoin</p>
              </div>

              <div className="space-y-4">
                <div>
                  <label htmlFor="wizard-name" className="block text-sm font-semibold text-gray-700 mb-2">
                    Memecoin Name *
                  </label>
                  <input
                    id="wizard-name"
                    type="text"
                    value={wizardData.name}
                    onChange={(e) => setWizardData({ ...wizardData, name: e.target.value })}
                    placeholder="e.g., MoonDoge"
                    className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition"
                  />
                </div>

                <div>
                  <label htmlFor="wizard-theme" className="block text-sm font-semibold text-gray-700 mb-2">
                    Theme *
                  </label>
                  <select
                    id="wizard-theme"
                    value={wizardData.theme}
                    onChange={(e) => setWizardData({ ...wizardData, theme: e.target.value })}
                    className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent transition"
                  >
                    <option value="">Select a theme...</option>
                    <option value="space">🚀 Space & Cosmos</option>
                    <option value="gaming">🎮 Gaming</option>
                    <option value="meme">😂 Classic Meme</option>
                    <option value="animal">🐕 Animals</option>
                    <option value="food">🍕 Food & Drinks</option>
                    <option value="tech">💻 Technology</option>
                    <option value="nature">🌿 Nature</option>
                    <option value="fantasy">🧙 Fantasy</option>
                  </select>
                </div>

                {/* AI Chat Helper */}
                <div className="mt-8 pt-8 border-t">
                  <h3 className="text-lg font-bold text-gray-900 mb-4">💬 Need Help?</h3>
                  <AIChat context={{ step: 'basic-info' }} className="h-[500px]" />
                </div>
              </div>
            </div>
          )}

          {/* Step 2: Logo Generation */}
          {currentStep === 2 && (
            <div>
              <LogoGenerator onLogoGenerated={handleLogoGenerated} />
            </div>
          )}

          {/* Step 3: Parameters */}
          {currentStep === 3 && (
            <div>
              <ParameterSuggester onSuggestionsGenerated={handleSuggestionsGenerated} />
            </div>
          )}

          {/* Step 4: Review */}
          {currentStep === 4 && (
            <div className="space-y-6">
              <div>
                <h2 className="text-2xl font-bold text-gray-900 mb-2">✅ Review & Deploy</h2>
                <p className="text-gray-600">Review your memecoin details before deployment</p>
              </div>

              {/* Summary Cards */}
              <div className="grid md:grid-cols-2 gap-6">
                {/* Basic Info */}
                <div className="bg-gradient-to-br from-blue-50 to-indigo-50 p-6 rounded-lg border border-blue-200">
                  <h3 className="text-lg font-bold text-blue-900 mb-4">📝 Basic Info</h3>
                  <div className="space-y-2">
                    <div>
                      <span className="text-sm text-blue-700 font-medium">Name:</span>
                      <p className="text-lg font-bold text-blue-900">{wizardData.name}</p>
                    </div>
                    <div>
                      <span className="text-sm text-blue-700 font-medium">Theme:</span>
                      <p className="text-lg font-bold text-blue-900 capitalize">{wizardData.theme}</p>
                    </div>
                  </div>
                </div>

                {/* Logo */}
                <div className="bg-gradient-to-br from-purple-50 to-pink-50 p-6 rounded-lg border border-purple-200">
                  <h3 className="text-lg font-bold text-purple-900 mb-4">🎨 Logo</h3>
                  {wizardData.logoUrl && (
                    <div className="aspect-square w-full bg-white rounded-lg overflow-hidden border-2 border-purple-200">
                      <img
                        src={wizardData.logoUrl}
                        alt={`${wizardData.name} logo`}
                        className="w-full h-full object-contain"
                      />
                    </div>
                  )}
                </div>
              </div>

              {/* Tokenomics Summary */}
              {wizardData.suggestions && (
                <div className="bg-gradient-to-br from-green-50 to-emerald-50 p-6 rounded-lg border border-green-200">
                  <h3 className="text-lg font-bold text-green-900 mb-4">💡 Tokenomics</h3>
                  <div className="grid md:grid-cols-3 gap-4">
                    <div>
                      <span className="text-sm text-green-700 font-medium">Total Supply</span>
                      <p className="text-xl font-bold text-green-900">{wizardData.suggestions.tokenomics.totalSupply}</p>
                    </div>
                    <div>
                      <span className="text-sm text-green-700 font-medium">Base APY</span>
                      <p className="text-xl font-bold text-green-900">{wizardData.suggestions.staking.baseAPY}</p>
                    </div>
                    <div>
                      <span className="text-sm text-green-700 font-medium">Initial Price</span>
                      <p className="text-xl font-bold text-green-900">${wizardData.suggestions.tokenomics.initialPrice}</p>
                    </div>
                  </div>
                </div>
              )}

              {/* Deploy Button */}
              <div className="pt-6">
                <button
                  onClick={() => alert('Deployment coming soon! Smart contract integration in progress.')}
                  className="w-full bg-gradient-to-r from-green-600 to-emerald-600 text-white font-bold py-4 px-6 rounded-lg hover:from-green-700 hover:to-emerald-700 transition shadow-lg hover:shadow-xl text-lg"
                >
                  🚀 Deploy Memecoin
                </button>
                <p className="text-center text-sm text-gray-500 mt-3">
                  Smart contract deployment will be available in the next phase
                </p>
              </div>
            </div>
          )}

          {/* Navigation Buttons */}
          <div className="flex justify-between mt-8 pt-6 border-t">
            <button
              onClick={() => setCurrentStep((prev) => Math.max(1, prev - 1))}
              disabled={currentStep === 1}
              className="px-6 py-3 bg-gray-200 text-gray-700 font-semibold rounded-lg hover:bg-gray-300 transition disabled:opacity-50 disabled:cursor-not-allowed"
            >
              ← Previous
            </button>

            <button
              onClick={() => setCurrentStep((prev) => Math.min(4, prev + 1))}
              disabled={currentStep === 4 || !canProceed(currentStep)}
              className="px-6 py-3 bg-blue-600 text-white font-semibold rounded-lg hover:bg-blue-700 transition disabled:opacity-50 disabled:cursor-not-allowed shadow-md hover:shadow-lg"
            >
              Next →
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
