import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class UpdateProductDto {
  @ApiProperty({ description: 'Nombre del producto', required: false, example: 'Producto Ejemplo' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiProperty({ description: 'Costo del producto', required: false, example: 10.5 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  cost?: number;

  @ApiProperty({ description: 'Precio de venta del producto', required: false, example: 15.99 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  price?: number;

  @ApiProperty({ description: 'Código de barras del producto', required: false, example: '1234567890123' })
  @IsOptional()
  @IsString()
  barcode?: string;
}
