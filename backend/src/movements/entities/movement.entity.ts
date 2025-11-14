import { MovementType } from '../../common/enums/movement-type.enum';

export class Movement {
  id: number;
  productId: number;
  type: MovementType;
  quantity: number;
  createdAt: Date;
}
