
import React, { useState, useEffect } from 'react';
import type { Product, Movement } from './api';
import { MovementType, api } from './api';
import Header from './components/Header';
import Dashboard from './components/Dashboard';
import AddProductModal from './components/AddProductModal';
import RecordMovementModal from './components/RecordMovementModal';

const App: React.FC = () => {
  const [products, setProducts] = useState<Product[]>([]);
  const [movements, setMovements] = useState<Movement[]>([]);
  const [isAddProductModalOpen, setAddProductModalOpen] = useState(false);
  const [isRecordMovementModalOpen, setRecordMovementModalOpen] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Cargar productos y movimientos al iniciar
  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      setError(null);
      console.log('Cargando datos...');
      const [productsData, movementsData] = await Promise.all([
        api.getProducts(),
        api.getMovements(),
      ]);
      console.log('Datos cargados - Productos:', productsData);
      console.log('Datos cargados - Movimientos:', movementsData);
      setProducts(productsData);
      setMovements(movementsData);
    } catch (err: any) {
      const errorMessage = err?.message || 'Error al cargar los datos. Asegúrate de que el backend esté corriendo.';
      setError(errorMessage);
      console.error('Error loading data:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleAddProduct = async (product: { name: string; cost: number; price: number; barcode?: string }) => {
    try {
      setError(null);
      // El modal ahora pasa cost, price, barcode en lugar de description, stock
      const newProduct = await api.createProduct(product);
      setProducts(prevProducts => [newProduct, ...prevProducts]);
      setAddProductModalOpen(false);
      // Recargar productos para obtener el stock actualizado
      await loadData();
    } catch (err: any) {
      setError(err.message || 'Error al crear el producto');
      console.error('Error creating product:', err);
    }
  };

  const handleRecordMovement = async (movement: Omit<Movement, 'id' | 'date' | 'productName'>) => {
    try {
      setError(null);
      const newMovement = await api.createMovement(movement);
      setMovements(prevMovements => [newMovement, ...prevMovements]);
      setRecordMovementModalOpen(false);
      // Recargar productos para obtener el stock actualizado
      await loadData();
    } catch (err: any) {
      setError(err.message || 'Error al crear el movimiento');
      console.error('Error creating movement:', err);
    }
  };

  return (
    <div className="min-h-screen bg-slate-900 text-slate-200 font-sans">
      <Header
        onAddProductClick={() => setAddProductModalOpen(true)}
        onRecordMovementClick={() => setRecordMovementModalOpen(true)}
      />
      <main className="container mx-auto p-4 md:p-8">
        {error && (
          <div className="mb-4 p-4 bg-red-900/50 border border-red-700 rounded-lg text-red-200">
            <p className="font-semibold">Error:</p>
            <p>{error}</p>
            <button
              onClick={loadData}
              className="mt-2 text-sm underline hover:text-red-100"
            >
              Reintentar
            </button>
          </div>
        )}
        {loading ? (
          <div className="text-center py-20">
            <p className="text-slate-400 text-lg">Cargando...</p>
          </div>
        ) : (
          <Dashboard products={products} />
        )}
      </main>
      
      <AddProductModal
        isOpen={isAddProductModalOpen}
        onClose={() => setAddProductModalOpen(false)}
        onAddProduct={handleAddProduct}
      />

      <RecordMovementModal
        isOpen={isRecordMovementModalOpen}
        onClose={() => setRecordMovementModalOpen(false)}
        onRecordMovement={handleRecordMovement}
        products={products}
      />
    </div>
  );
};

export default App;
