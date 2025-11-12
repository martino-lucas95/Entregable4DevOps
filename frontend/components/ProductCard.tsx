
import React from 'react';
import type { Product } from '../api';

interface ProductCardProps {
  product: Product;
}

const StockIndicator: React.FC<{ stock: number }> = ({ stock }) => {
  let bgColor = 'bg-green-500';
  let textColor = 'text-green-100';
  let text = 'En Stock';

  if (stock === 0) {
    bgColor = 'bg-red-500';
    textColor = 'text-red-100';
    text = 'Sin Stock';
  } else if (stock <= 10) {
    bgColor = 'bg-yellow-500';
    textColor = 'text-yellow-100';
    text = 'Stock Bajo';
  }

  return (
    <div className={`absolute top-4 right-4 text-xs font-bold px-2 py-1 rounded-full ${bgColor} ${textColor}`}>
      {text}
    </div>
  );
};

const ProductCard: React.FC<ProductCardProps> = ({ product }) => {
  return (
    <div className="bg-slate-800 rounded-lg shadow-lg overflow-hidden transform hover:-translate-y-1 transition-transform duration-300 relative">
      <div className="p-6">
        <StockIndicator stock={product.stock} />
        <h3 className="text-xl font-bold text-slate-100 mb-2 truncate">{product.name}</h3>
        <p className="text-slate-400 text-sm mb-4 h-10">{product.description}</p>
        <div className="mt-4 pt-4 border-t border-slate-700 flex justify-between items-center">
          <span className="text-sm text-slate-500">Stock actual</span>
          <span className="text-2xl font-bold text-indigo-400">{product.stock}</span>
        </div>
      </div>
    </div>
  );
};

export default ProductCard;
