
import React, { useState, FormEvent } from 'react';
import Modal from './Modal';

interface AddProductModalProps {
  isOpen: boolean;
  onClose: () => void;
  onAddProduct: (product: { name: string; cost: number; price: number; barcode?: string }) => void;
}

const AddProductModal: React.FC<AddProductModalProps> = ({ isOpen, onClose, onAddProduct }) => {
  const [name, setName] = useState('');
  const [cost, setCost] = useState('0');
  const [price, setPrice] = useState('0');
  const [barcode, setBarcode] = useState('');
  const [error, setError] = useState('');

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    const costNumber = parseFloat(cost);
    const priceNumber = parseFloat(price);

    if (!name.trim()) {
      setError('El nombre del producto es obligatorio.');
      return;
    }
    if (isNaN(costNumber) || costNumber < 0) {
      setError('El costo debe ser un número positivo.');
      return;
    }
    if (isNaN(priceNumber) || priceNumber < 0) {
      setError('El precio debe ser un número positivo.');
      return;
    }

    onAddProduct({ 
      name, 
      cost: costNumber, 
      price: priceNumber, 
      barcode: barcode.trim() || undefined 
    });
    // Reset form
    setName('');
    setCost('0');
    setPrice('0');
    setBarcode('');
    setError('');
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Añadir Nuevo Producto">
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label htmlFor="product-name" className="block text-sm font-medium text-slate-400 mb-1">Nombre</label>
          <input
            id="product-name"
            type="text"
            value={name}
            onChange={e => setName(e.target.value)}
            className="w-full bg-slate-700 border-slate-600 text-white rounded-md p-2 focus:ring-indigo-500 focus:border-indigo-500"
            required
          />
        </div>
        <div>
          <label htmlFor="product-cost" className="block text-sm font-medium text-slate-400 mb-1">Costo</label>
          <input
            id="product-cost"
            type="number"
            step="0.01"
            value={cost}
            onChange={e => setCost(e.target.value)}
            className="w-full bg-slate-700 border-slate-600 text-white rounded-md p-2 focus:ring-indigo-500 focus:border-indigo-500"
            min="0"
            required
          />
        </div>
        <div>
          <label htmlFor="product-price" className="block text-sm font-medium text-slate-400 mb-1">Precio de Venta</label>
          <input
            id="product-price"
            type="number"
            step="0.01"
            value={price}
            onChange={e => setPrice(e.target.value)}
            className="w-full bg-slate-700 border-slate-600 text-white rounded-md p-2 focus:ring-indigo-500 focus:border-indigo-500"
            min="0"
            required
          />
        </div>
        <div>
          <label htmlFor="product-barcode" className="block text-sm font-medium text-slate-400 mb-1">Código de Barras (opcional)</label>
          <input
            id="product-barcode"
            type="text"
            value={barcode}
            onChange={e => setBarcode(e.target.value)}
            className="w-full bg-slate-700 border-slate-600 text-white rounded-md p-2 focus:ring-indigo-500 focus:border-indigo-500"
          />
        </div>
        {error && <p className="text-sm text-red-400">{error}</p>}
        <div className="flex justify-end gap-4 pt-4">
          <button type="button" onClick={onClose} className="bg-slate-600 hover:bg-slate-500 text-white font-bold py-2 px-4 rounded-lg transition-colors">
            Cancelar
          </button>
          <button type="submit" className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-2 px-4 rounded-lg transition-colors">
            Añadir Producto
          </button>
        </div>
      </form>
    </Modal>
  );
};

export default AddProductModal;
