import React from 'react';

type Vendor = {
  id: number;
  name: string;
  tagline?: string;
  specialties?: string[];
  distanceKm?: number;
  avatarUrl?: string;
};

export const VendorCard: React.FC<{ vendor: Vendor }> = ({ vendor }) => {
  return (
    <div className="bg-white rounded-lg shadow p-4 flex items-center space-x-4">
      <img src={vendor.avatarUrl || '/default-avatar.png'} alt={`${vendor.name} avatar`} className="w-16 h-16 rounded-full object-cover" />
      <div className="flex-1">
        <div className="font-semibold">{vendor.name}</div>
        <div className="text-sm text-gray-500">{vendor.tagline}</div>
        <div className="text-xs text-gray-400 mt-1">{vendor.specialties?.slice(0,3).join(' • ')}</div>
      </div>
      <div className="text-right">
        <div className="text-sm">{vendor.distanceKm ? vendor.distanceKm.toFixed(1) + ' km' : ''}</div>
        <div className="flex flex-col mt-2 space-y-1">
          <button className="text-xs px-2 py-1 bg-indigo-50 text-indigo-600 rounded">Story</button>
          <button className="text-xs px-2 py-1 bg-green-50 text-green-600 rounded">Voice</button>
        </div>
      </div>
    </div>
  );
};

export default VendorCard;
