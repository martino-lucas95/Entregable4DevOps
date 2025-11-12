
import React from 'react';
import type { Product } from '../api';
import ProductCard from './ProductCard';

interface DashboardProps {
  products: Product[];
}

const Dashboard: React.FC<DashboardProps> = ({ products }) => {
  if (products.length === 0) {
    return (
      <div className="text-center py-20">
        <p className="text-slate-400 text-lg">No hay productos en el inventario.</p>
        <p className="text-slate-500 mt-2">Empieza añadiendo tu primer producto.</p>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
      {products.map(product => (
        <ProductCard key={product.id} product={product} />
      ))}
    </div>
  );
};

export default Dashboard;
