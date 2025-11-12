
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
