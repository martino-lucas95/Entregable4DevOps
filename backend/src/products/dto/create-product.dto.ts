import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class CreateProductDto {
  @ApiProperty({ description: 'Nombre del producto', example: 'Producto Ejemplo' })
  @IsString()
  name: string;

  @ApiProperty({ description: 'Costo del producto', example: 10.5 })
  @IsNumber()
  @Min(0)
  cost: number;

  @ApiProperty({ description: 'Precio de venta del producto', example: 15.99 })
  @IsNumber()
  @Min(0)
  price: number;

  @ApiProperty({ description: 'Código de barras del producto', required: false, example: '1234567890123' })
  @IsOptional()
  @IsString()
  barcode?: string;
}
