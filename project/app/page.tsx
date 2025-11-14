'use client';

import { useState } from 'react';

export default function Home() {
  const [selectedProblem, setSelectedProblem] = useState('');
  const [currentPage, setCurrentPage] = useState<'input' | 'diagnostic' | 'draft' | 'impact'>('input');
  
  const policyProblems = [
    'Agricultural subsidy reform for smallholder farmers',
    'Digital identification system for citizen services',
    'Renewable energy transition in rural areas'
  ];

  const handleProblemSelect = (problem: string) => {
    setSelectedProblem(problem);
  };

  const handleSubmit = () => {
    if (selectedProblem) {
      setCurrentPage('diagnostic');
    }
  };

  const renderPage = () => {
    switch (currentPage) {
      case 'input':
        return (
          <div className="min-h-screen bg-gradient-to-br from-green-50 via-white to-black-5">
            {/* Kenyan Flag - Horizontal Bands */}
            <div className="w-full h-24 flex">
              <div className="flex-1 bg-black"></div>
              <div className="flex-1 bg-red-600"></div>
              <div className="flex-1 bg-green-600 flex items-center justify-center">
                <div className="w-12 h-12">
                  <svg viewBox="0 0 100 100" className="w-full h-full">
                    <polygon points="50,10 61,35 88,35 67,52 78,77 50,60 22,77 33,52 12,35 39,35" fill="white"/>
                  </svg>
                </div>
              </div>
            </div>

            <div className="max-w-4xl mx-auto px-8 py-12">
              {/* Header */}
              <div className="text-center mb-12">
                <h1 className="text-5xl font-bold bg-gradient-to-r from-green-700 to-red-600 bg-clip-text text-transparent mb-4">
                  Policy Forecaster
                </h1>
                <p className="text-gray-600 text-lg">Democratizing Policy Analysis for Kenya</p>
              </div>

              {/* Policy Input - At the top under title */}
              <div className="bg-white rounded-2xl shadow-xl p-8 mb-8">
                <div className="mb-6">
                  <label className="block text-sm font-semibold text-gray-700 mb-3">
                    Describe the policy problem you want to analyze:
                  </label>
                  <textarea
                    value={selectedProblem}
                    onChange={(e) => setSelectedProblem(e.target.value)}
                    placeholder="Enter your policy problem or click a suggestion below..."
                    className="w-full h-32 px-4 py-3 border-2 border-gray-200 rounded-xl focus:border-green-500 focus:outline-none resize-none transition-colors"
                  />
                </div>

                <button
                  onClick={handleSubmit}
                  disabled={!selectedProblem}
                  className="w-full py-4 bg-gradient-to-r from-green-600 to-green-700 text-white font-semibold rounded-xl hover:from-green-700 hover:to-green-800 disabled:from-gray-300 disabled:to-gray-400 disabled:cursor-not-allowed transition-all transform hover:scale-105 shadow-lg"
                >
                  Analyze Policy Problem
                </button>
              </div>

              {/* Suggested Problems - Below input, as clickable faded text */}
              <div className="bg-white rounded-2xl shadow-xl p-8">
                <h3 className="text-xl font-semibold text-gray-800 mb-6">Suggested Policy Problems</h3>
                <div className="space-y-3">
                  {policyProblems.map((problem, index) => (
                    <div
                      key={index}
                      onClick={() => handleProblemSelect(problem)}
                      className="text-gray-400 hover:text-green-600 cursor-pointer transition-colors text-lg py-2"
                    >
                      {problem}
                    </div>
                  ))}
                </div>
              </div>

              {/* Responsible AI Section - At the very bottom */}
              <div className="mt-16 bg-gray-50 rounded-xl p-6 border border-gray-200">
                <h4 className="text-xs font-semibold text-gray-500 mb-3">Responsible AI Disclosure</h4>
                <div className="text-xs text-gray-400 space-y-2">
                  <p><span className="font-medium">Sources:</span> Kenya National Bureau of Statistics (2019-2023), World Bank Development Indicators, Kenya Law Reports, Constitution of Kenya 2010</p>
                  <p><span className="font-medium">Confidence Score:</span> 78% - Based on historical policy patterns and socio-economic correlations</p>
                  <p><span className="font-medium">Potential Bias:</span> Analysis may reflect urban-centric data collection; rural informal economy underrepresented</p>
                  <p><span className="font-medium">Warnings:</span> This tool provides simulated analysis for demonstration purposes only. Real policy decisions require comprehensive stakeholder consultation and expert legal review.</p>
                  <p><span className="font-medium">Limitations:</span> Does not account for political feasibility, regional variations, or implementation capacity constraints. Impact projections are simplified models.</p>
                </div>
              </div>
            </div>
          </div>
        );

      case 'diagnostic':
        return (
          <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50 p-8">
            <div className="max-w-6xl mx-auto">
              <button 
                onClick={() => setCurrentPage('input')}
                className="mb-6 px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
              >
                ← Back
              </button>
              
              <div className="bg-white rounded-2xl shadow-xl p-8">
                <h2 className="text-3xl font-bold text-gray-800 mb-6">Policy Diagnostic Report</h2>
                <div className="prose max-w-none">
                  <h3 className="text-xl font-semibold text-gray-700 mb-4">Problem: {selectedProblem}</h3>
                  
                  <div className="grid md:grid-cols-2 gap-6 mb-8">
                    <div className="bg-red-50 p-6 rounded-xl border-l-4 border-red-500">
                      <h4 className="font-semibold text-red-800 mb-3">🔴 Contradictions Identified</h4>
                      <ul className="text-sm text-red-700 space-y-1">
                        <li>• Current subsidy structure conflicts with WTO agreements</li>
                        <li>• Regional trade protocols create implementation gaps</li>
                      </ul>
                    </div>
                    
                    <div className="bg-yellow-50 p-6 rounded-xl border-l-4 border-yellow-500">
                      <h4 className="font-semibold text-yellow-800 mb-3">🟡 Gaps & Inefficiencies</h4>
                      <ul className="text-sm text-yellow-700 space-y-1">
                        <li>• 40% of eligible farmers lack access to subsidy programs</li>
                        <li>• Administrative costs consume 25% of total budget</li>
                      </ul>
                    </div>
                  </div>

                  <div className="bg-green-50 p-6 rounded-xl border-l-4 border-green-500 mb-8">
                    <h4 className="font-semibold text-green-800 mb-3">🟢 Opportunities</h4>
                    <ul className="text-sm text-green-700 space-y-1">
                      <li>• Digital registration could reduce costs by 60%</li>
                      <li>• Regional cooperation could increase market access by 35%</li>
                      <li>• Climate-smart agriculture integration potential</li>
                    </ul>
                  </div>

                  <button
                    onClick={() => setCurrentPage('draft')}
                    className="w-full py-4 bg-gradient-to-r from-blue-600 to-purple-600 text-white font-semibold rounded-xl hover:from-blue-700 hover:to-purple-700 transition-all transform hover:scale-105 shadow-lg"
                  >
                    Generate Legislative Draft →
                  </button>
                </div>
              </div>
            </div>
          </div>
        );

      case 'draft':
        return (
          <div className="min-h-screen bg-gradient-to-br from-purple-50 via-white to-blue-50 p-8">
            <div className="max-w-6xl mx-auto">
              <button 
                onClick={() => setCurrentPage('diagnostic')}
                className="mb-6 px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
              >
                ← Back
              </button>
              
              <div className="bg-white rounded-2xl shadow-xl p-8">
                <h2 className="text-3xl font-bold text-gray-800 mb-6">Legislative Draft</h2>
                
                <div className="bg-gray-50 p-6 rounded-xl mb-6">
                  <h3 className="text-xl font-semibold text-gray-700 mb-4">Agricultural Subsidy Reform Act, 2024</h3>
                  
                  <div className="space-y-4 text-sm">
                    <div>
                      <h4 className="font-semibold text-gray-800 mb-2">Article 1: Purpose and Scope</h4>
                      <p className="text-gray-600 italic">"To establish a transparent, efficient, and equitable agricultural subsidy system for smallholder farmers in Kenya."</p>
                      <p className="text-xs text-gray-500 mt-1">Cites: Constitution of Kenya, Article 43(1)(c) - Right to be free from hunger</p>
                    </div>
                    
                    <div>
                      <h4 className="font-semibold text-gray-800 mb-2">Article 2: Eligibility Criteria</h4>
                      <ul className="text-gray-600 space-y-1">
                        <li>• Landholding not exceeding 5 hectares</li>
                        <li>• Active registration in national farmer database</li>
                        <li>• Compliance with environmental protection standards</li>
                      </ul>
                    </div>
                    
                    <div>
                      <h4 className="font-semibold text-gray-800 mb-2">Article 3: Implementation Framework</h4>
                      <p className="text-gray-600">Establishes County Agricultural Subsidy Committees with representation from...</p>
                    </div>
                  </div>
                </div>

                <button
                  onClick={() => setCurrentPage('impact')}
                  className="w-full py-4 bg-gradient-to-r from-purple-600 to-pink-600 text-white font-semibold rounded-xl hover:from-purple-700 hover:to-pink-700 transition-all transform hover:scale-105 shadow-lg"
                >
                  Simulate 5-Year Impact →
                </button>
              </div>
            </div>
          </div>
        );

      case 'impact':
        return (
          <div className="min-h-screen bg-gradient-to-br from-pink-50 via-white to-purple-50 p-8">
            <div className="max-w-6xl mx-auto">
              <button 
                onClick={() => setCurrentPage('draft')}
                className="mb-6 px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
              >
                ← Back
              </button>
              
              <div className="bg-white rounded-2xl shadow-xl p-8">
                <h2 className="text-3xl font-bold text-gray-800 mb-6">5-Year Impact Simulation</h2>
                
                <div className="grid md:grid-cols-3 gap-6 mb-8">
                  <div className="bg-green-50 p-6 rounded-xl">
                    <h4 className="font-semibold text-green-800 mb-2">Economic Impact</h4>
                    <div className="text-3xl font-bold text-green-600">+23%</div>
                    <p className="text-sm text-green-700">Average farmer income increase</p>
                  </div>
                  
                  <div className="bg-blue-50 p-6 rounded-xl">
                    <h4 className="font-semibold text-blue-800 mb-2">Coverage</h4>
                    <div className="text-3xl font-bold text-blue-600">85%</div>
                    <p className="text-sm text-blue-700">Eligible farmers reached</p>
                  </div>
                  
                  <div className="bg-purple-50 p-6 rounded-xl">
                    <h4 className="font-semibold text-purple-800 mb-2">Efficiency</h4>
                    <div className="text-3xl font-bold text-purple-600">-40%</div>
                    <p className="text-sm text-purple-700">Administrative cost reduction</p>
                  </div>
                </div>

                <div className="bg-gray-50 p-6 rounded-xl mb-6">
                  <h4 className="font-semibold text-gray-800 mb-4">Stakeholder Analysis</h4>
                  <div className="space-y-3">
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-medium">Smallholder Farmers</span>
                      <span className="text-green-600 font-semibold">+ Highly Positive</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-medium">County Governments</span>
                      <span className="text-blue-600 font-semibold">+ Positive</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-sm font-medium">Large Agribusiness</span>
                      <span className="text-yellow-600 font-semibold">~ Neutral</span>
                    </div>
                  </div>
                </div>

                <div className="bg-yellow-50 p-4 rounded-xl border-l-4 border-yellow-500">
                  <h4 className="font-semibold text-yellow-800 mb-2">⚠️ Key Assumptions</h4>
                  <ul className="text-sm text-yellow-700 space-y-1">
                    <li>• Stable macroeconomic environment</li>
                    <li>• Successful digital infrastructure rollout</li>
                    <li>• Average rainfall patterns maintained</li>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        );

      default:
        return null;
    }
  };

  return renderPage();
}
