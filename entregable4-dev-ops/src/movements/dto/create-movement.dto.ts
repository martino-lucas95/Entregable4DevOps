import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsNumber, IsPositive } from 'class-validator';
import { MovementType } from '../../common/enums/movement-type.enum';

export class CreateMovementDto {
  @ApiProperty({ description: 'ID del producto', example: 1 })
  @IsNumber()
  productId: number;

  @ApiProperty({ description: 'Tipo de movimiento', enum: MovementType, example: MovementType.IN })
  @IsEnum(MovementType)
  type: MovementType;

  @ApiProperty({ description: 'Cantidad del movimiento', example: 10 })
  @IsPositive()
  @IsNumber()
  quantity: number;
}
