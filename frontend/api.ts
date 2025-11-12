// Configuración de la API
const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000';

// Log para debugging
console.log('API_URL configurada:', API_URL);
console.log('VITE_API_URL env:', import.meta.env.VITE_API_URL);

// Tipos del backend
interface BackendProduct {
  id: number;
  uuid: string;
  name: string;
  cost: number;
  price: number;
  barcode: string | null;
  createdAt: string;
  updatedAt: string;
}

interface BackendMovement {
  id: number;
  productId: number;
  type: 'IN' | 'OUT';
  quantity: number;
  createdAt: string;
}

interface StockInfo {
  productId: number;
  name: string;
  stock: number;
}

// Tipos del frontend
export interface Product {
  id: string;
  name: string;
  description: string;
  stock: number;
}

export enum MovementType {
  IN = 'in',
  OUT = 'out',
}

export interface Movement {
  id: string;
  productId: string;
  productName: string;
  type: MovementType;
  quantity: number;
  date: Date;
}

// Función helper para convertir producto del backend al frontend
function mapBackendProductToFrontend(
  backendProduct: BackendProduct,
  stock: number
): Product {
  return {
    id: backendProduct.id.toString(),
    name: backendProduct.name,
    description: backendProduct.barcode || `Costo: $${backendProduct.cost}, Precio: $${backendProduct.price}`,
    stock,
  };
}

// Función helper para convertir movimiento del backend al frontend
function mapBackendMovementToFrontend(
  backendMovement: BackendMovement,
  productName: string
): Movement {
  return {
    id: backendMovement.id.toString(),
    productId: backendMovement.productId.toString(),
    productName,
    type: backendMovement.type === 'IN' ? MovementType.IN : MovementType.OUT,
    quantity: backendMovement.quantity,
    date: new Date(backendMovement.createdAt),
  };
}

// Servicio API
export const api = {
  // Obtener todos los productos con su stock
  async getProducts(): Promise<Product[]> {
    try {
      console.log('Fetching products from:', `${API_URL}/products`);
      console.log('Fetching stock from:', `${API_URL}/stock`);
      
      // Obtener productos primero (es crítico)
      const productsResponse = await fetch(`${API_URL}/products`);
      console.log('Products response status:', productsResponse.status);

      if (!productsResponse.ok) {
        const errorText = await productsResponse.text();
        console.error('Error en productos response:', errorText);
        throw new Error(`Error al obtener productos: ${productsResponse.status} ${errorText}`);
      }

      const products: BackendProduct[] = await productsResponse.json();
      console.log('Products recibidos:', products);

      // Intentar obtener stock, pero si falla, usar stock 0 para todos
      let stockMap = new Map<number, number>();
      try {
        const stockResponse = await fetch(`${API_URL}/stock`);
        console.log('Stock response status:', stockResponse.status);

        if (stockResponse.ok) {
          const stockList: StockInfo[] = await stockResponse.json();
          console.log('Stock recibido:', stockList);
          stockList.forEach((item) => {
            stockMap.set(item.productId, item.stock);
          });
        } else {
          console.warn('No se pudo obtener stock, usando stock 0 para todos los productos');
        }
      } catch (stockError) {
        console.warn('Error al obtener stock, usando stock 0:', stockError);
      }

      // Combinar productos con su stock
      const mappedProducts = products.map((product) =>
        mapBackendProductToFrontend(product, stockMap.get(product.id) || 0)
      );
      
      console.log('Productos mapeados:', mappedProducts);
      return mappedProducts;
    } catch (error) {
      console.error('Error fetching products:', error);
      throw error;
    }
  },

  // Crear un nuevo producto
  async createProduct(product: {
    name: string;
    cost: number;
    price: number;
    barcode?: string;
  }): Promise<Product> {
    try {
      const response = await fetch(`${API_URL}/products`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(product),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.message || 'Error al crear producto');
      }

      const backendProduct: BackendProduct = await response.json();
      // El stock inicial será 0 hasta que se cree un movimiento
      return mapBackendProductToFrontend(backendProduct, 0);
    } catch (error) {
      console.error('Error creating product:', error);
      throw error;
    }
  },

  // Crear un nuevo movimiento
  async createMovement(movement: {
    productId: string;
    type: MovementType;
    quantity: number;
  }): Promise<Movement> {
    try {
      // Primero obtener el nombre del producto
      const productResponse = await fetch(
        `${API_URL}/products/${movement.productId}`
      );
      if (!productResponse.ok) {
        throw new Error('Producto no encontrado');
      }
      const product: BackendProduct = await productResponse.json();

      // Crear el movimiento
      const response = await fetch(`${API_URL}/movements`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          productId: parseInt(movement.productId),
          type: movement.type === MovementType.IN ? 'IN' : 'OUT',
          quantity: movement.quantity,
        }),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.message || 'Error al crear movimiento');
      }

      const backendMovement: BackendMovement = await response.json();
      return mapBackendMovementToFrontend(backendMovement, product.name);
    } catch (error) {
      console.error('Error creating movement:', error);
      throw error;
    }
  },

  // Obtener todos los movimientos
  async getMovements(): Promise<Movement[]> {
    try {
      const [movementsResponse, productsResponse] = await Promise.all([
        fetch(`${API_URL}/movements`),
        fetch(`${API_URL}/products`),
      ]);

      if (!movementsResponse.ok) {
        throw new Error('Error al obtener movimientos');
      }
      if (!productsResponse.ok) {
        throw new Error('Error al obtener productos');
      }

      const movements: BackendMovement[] = await movementsResponse.json();
      const products: BackendProduct[] = await productsResponse.json();

      // Crear un mapa de productos por ID
      const productMap = new Map<number, string>();
      products.forEach((product) => {
        productMap.set(product.id, product.name);
      });

      return movements.map((movement) =>
        mapBackendMovementToFrontend(
          movement,
          productMap.get(movement.productId) || 'Producto desconocido'
        )
      );
    } catch (error) {
      console.error('Error fetching movements:', error);
      throw error;
    }
  },
};

