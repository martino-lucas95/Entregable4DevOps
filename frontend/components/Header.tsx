
import React from 'react';
import PlusIcon from './icons/PlusIcon';
import BoxIcon from './icons/BoxIcon';

interface HeaderProps {
  onAddProductClick: () => void;
  onRecordMovementClick: () => void;
}

const Header: React.FC<HeaderProps> = ({ onAddProductClick, onRecordMovementClick }) => {
  return (
    <header className="bg-slate-800/50 backdrop-blur-sm sticky top-0 z-10 shadow-lg shadow-slate-900/50">
      <div className="container mx-auto px-4 md:px-8 py-4 flex justify-between items-center">
        <div className="flex items-center gap-3">
            <BoxIcon className="w-8 h-8 text-indigo-400"/>
            <h1 className="text-xl md:text-2xl font-bold text-slate-100">
            Gestión de Stock
            </h1>
        </div>
        <div className="flex items-center gap-2 md:gap-4">
          <button
            onClick={onRecordMovementClick}
            className="bg-slate-700 hover:bg-slate-600 text-slate-200 font-semibold py-2 px-4 rounded-lg flex items-center gap-2 transition-colors duration-200 text-sm md:text-base"
          >
            Registrar Movimiento
          </button>
          <button
            onClick={onAddProductClick}
            className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-2 px-4 rounded-lg flex items-center gap-2 transition-colors duration-200 text-sm md:text-base"
          >
            <PlusIcon className="w-5 h-5" />
            <span className="hidden sm:inline">Añadir Producto</span>
          </button>
        </div>
      </div>
    </header>
  );
};

export default Header;
