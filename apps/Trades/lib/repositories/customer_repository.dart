// ZAFTO Customer Repository
// Created: Sprint B1b (Session 41)
//
// Supabase CRUD for customers table.
// RLS handles company scoping — no need to filter by company_id manually.

import '../core/errors.dart';
import '../core/supabase_client.dart';
import '../models/customer.dart';

class CustomerRepository {
  // ============================================================
  // READ
  // ============================================================

  Future<List<Customer>> getCustomers() async {
    try {
      final response = await supabase
          .from('customers')
          .select()
          .order('name', ascending: true);
      return (response as List).map((row) => Customer.fromJson(row)).toList();
    } catch (e) {
      throw DatabaseError('Failed to fetch customers: $e', cause: e);
    }
  }

  Future<Customer?> getCustomer(String id) async {
    try {
      final response = await supabase
          .from('customers')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return Customer.fromJson(response);
    } catch (e) {
      throw DatabaseError('Failed to fetch customer: $e', cause: e);
    }
  }

  Future<List<Customer>> searchCustomers(String query) async {
    try {
      final q = '%$query%';
      final response = await supabase
          .from('customers')
          .select()
          .or('name.ilike.$q,email.ilike.$q,phone.ilike.$q,company_name.ilike.$q')
          .order('name', ascending: true);
      return (response as List).map((row) => Customer.fromJson(row)).toList();
    } catch (e) {
      throw DatabaseError('Failed to search customers: $e', cause: e);
    }
  }

  // ============================================================
  // WRITE
  // ============================================================

  Future<Customer> createCustomer(Customer customer) async {
    try {
      final response = await supabase
          .from('customers')
          .insert(customer.toInsertJson())
          .select()
          .single();
      return Customer.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to create customer: $e',
        userMessage: 'Could not create customer. Please try again.',
        cause: e,
      );
    }
  }

  Future<Customer> updateCustomer(String id, Customer customer) async {
    try {
      final response = await supabase
          .from('customers')
          .update(customer.toUpdateJson())
          .eq('id', id)
          .select()
          .single();
      return Customer.fromJson(response);
    } catch (e) {
      throw DatabaseError(
        'Failed to update customer: $e',
        userMessage: 'Could not update customer. Please try again.',
        cause: e,
      );
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await supabase
          .from('customers')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseError(
        'Failed to delete customer: $e',
        userMessage: 'Could not delete customer. Please try again.',
        cause: e,
      );
    }
  }
}
