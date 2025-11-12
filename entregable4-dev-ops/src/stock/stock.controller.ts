import { Controller, Get, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiParam } from '@nestjs/swagger';
import { StockService } from './stock.service';

@ApiTags('stock')
@Controller('stock')
export class StockController {
  constructor(private readonly stockService: StockService) {}

  @Get()
  @ApiOperation({ summary: 'Obtener el stock de todos los productos' })
  @ApiResponse({ status: 200, description: 'Lista de stock por producto' })
  findAll() {
    return this.stockService.findAll();
  }

  @Get(':productId')
  @ApiOperation({ summary: 'Obtener el stock de un producto específico' })
  @ApiParam({ name: 'productId', description: 'ID del producto' })
  @ApiResponse({ status: 200, description: 'Stock del producto' })
  findOne(@Param('productId') id: string) {
    return this.stockService.findOne(Number(id));
  }
}
