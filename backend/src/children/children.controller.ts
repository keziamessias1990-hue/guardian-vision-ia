import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { ChildRecord, CreateChildDto } from '../guardian.types';
import { mockChildren } from '../mock-data';

@Controller('children')
export class ChildrenController {
  @Get()
  list(): ChildRecord[] {
    return mockChildren;
  }

  @Get(':id')
  detail(@Param('id') id: string): ChildRecord | undefined {
    return mockChildren.find((child) => child.id === id);
  }

  @Post()
  create(@Body() body: CreateChildDto): ChildRecord {
    const child: ChildRecord = {
      id: `child-${Date.now()}`,
      parentId: body.parentId,
      name: body.name,
      ageGroup: body.ageGroup,
      status: 'pending',
      createdAt: new Date().toISOString(),
    };

    mockChildren.push(child);
    return child;
  }
}
