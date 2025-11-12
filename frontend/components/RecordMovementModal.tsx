
import React, { useState, FormEvent, useEffect } from 'react';
import type { Product, Movement } from '../api';
import { MovementType } from '../api';
import Modal from './Modal';
import ArrowUpIcon from './icons/ArrowUpIcon';
import ArrowDownIcon from './icons/ArrowDownIcon';

interface RecordMovementModalProps {
  isOpen: boolean;
  onClose: () => void;
  onRecordMovement: (movement: Omit<Movement, 'id' | 'date' | 'productName'>) => void;
  products: Product[];
}

const RecordMovementModal: React.FC<RecordMovementModalProps> = ({ isOpen, onClose, onRecordMovement, products }) => {
  const [productId, setProductId] = useState('');
  const [type, setType] = useState<MovementType>(MovementType.IN);
  const [quantity, setQuantity] = useState('1');
  const [error, setError] = useState('');

  useEffect(() => {
    if (products.length > 0 && !productId) {
      setProductId(products[0].id);
    }
  }, [products, productId]);

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    const quantityNumber = parseInt(quantity, 10);

    if (!productId) {
      setError('Por favor, selecciona un producto.');
      return;
    }
    if (isNaN(quantityNumber) || quantityNumber <= 0) {
      setError('La cantidad debe ser un número mayor que cero.');
      return;
    }

    const selectedProduct = products.find(p => p.id === productId);
    if (type === MovementType.OUT && selectedProduct && selectedProduct.stock < quantityNumber) {
      setError(`No hay stock suficiente. Stock actual: ${selectedProduct.stock}.`);
      return;
    }

    onRecordMovement({ productId, type, quantity: quantityNumber });
    // Reset form
    setProductId(products.length > 0 ? products[0].id : '');
    setType(MovementType.IN);
    setQuantity('1');
    setError('');
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Registrar Movimiento de Stock">
      <form onSubmit={handleSubmit} className="space-y-6">
        <div>
          <label htmlFor="product-select" className="block text-sm font-medium text-slate-400 mb-1">Producto</label>
          <select
            id="product-select"
            value={productId}
            onChange={e => setProductId(e.target.value)}
            className="w-full bg-slate-700 border-slate-600 text-white rounded-md p-2 focus:ring-indigo-500 focus:border-indigo-500"
            required
          >
            {products.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
          </select>
        </div>
        
        <div>
            <span className="block text-sm font-medium text-slate-400 mb-2">Tipo de Movimiento</span>
            <div className="grid grid-cols-2 gap-4">
                <button type="button" onClick={() => setType(MovementType.IN)} className={`flex flex-col items-center justify-center p-4 rounded-lg border-2 transition-colors ${type === MovementType.IN ? 'bg-green-500/20 border-green-500' : 'bg-slate-700 border-slate-600 hover:border-slate-500'}`}>
                    <ArrowUpIcon className="w-6 h-6 text-green-400 mb-1" />
                    <span className="font-semibold">Entrada</span>
                </button>
                <button type="button" onClick={() => setType(MovementType.OUT)} className={`flex flex-col items-center justify-center p-4 rounded-lg border-2 transition-colors ${type === MovementType.OUT ? 'bg-red-500/20 border-red-500' : 'bg-slate-700 border-slate-600 hover:border-slate-500'}`}>
                    <ArrowDownIcon className="w-6 h-6 text-red-400 mb-1" />
                    <span className="font-semibold">Salida</span>
                </button>
            </div>
        </div>

        <div>
          <label htmlFor="quantity" className="block text-sm font-medium text-slate-400 mb-1">Cantidad</label>
          <input
            id="quantity"
            type="number"
            value={quantity}
            onChange={e => setQuantity(e.target.value)}
            className="w-full bg-slate-700 border-slate-600 text-white rounded-md p-2 focus:ring-indigo-500 focus:border-indigo-500"
            min="1"
            required
          />
        </div>
        
        {error && <p className="text-sm text-red-400">{error}</p>}

        <div className="flex justify-end gap-4 pt-4">
          <button type="button" onClick={onClose} className="bg-slate-600 hover:bg-slate-500 text-white font-bold py-2 px-4 rounded-lg transition-colors">
            Cancelar
          </button>
          <button type="submit" className="bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-2 px-4 rounded-lg transition-colors">
            Registrar
          </button>
        </div>
      </form>
    </Modal>
  );
};

export default RecordMovementModal;
