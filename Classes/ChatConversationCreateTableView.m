//
//  MyTableViewController.m
//  UISearchDisplayController
//
//  Created by Phillip Harris on 4/19/14.
//  Copyright (c) 2014 Phillip Harris. All rights reserved.
//

#import "ChatConversationCreateTableView.h"
#import "UIChatCreateCell.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "UIChatCreateCollectionViewCell.h"

@interface ChatConversationCreateTableView ()

@property(nonatomic, strong) NSMutableDictionary *contacts;
@property(nonatomic, strong) NSDictionary *allContacts;
@end

@implementation ChatConversationCreateTableView

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	_allContacts =
		[[NSDictionary alloc] initWithDictionary:LinphoneManager.instance.fastAddressBook.addressBookMap];
	_contacts = [[NSMutableDictionary alloc] initWithCapacity:_allContacts.count];
	_contactsGroup = [[NSMutableArray alloc] init];
	_contactsDict = [[NSMutableDictionary alloc] init];
	_allFilter = TRUE;
	[_searchBar setText:@""];
	[self searchBar:_searchBar textDidChange:_searchBar.text];
	self.tableView.accessibilityIdentifier = @"Suggested addresses";
}

- (void) loadData {
	[self reloadDataWithFilter:_searchBar.text];
}

- (void)reloadDataWithFilter:(NSString *)filter {
	[_contacts removeAllObjects];

	[_allContacts enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
		NSString *address = (NSString *)key;
		NSString *name = [FastAddressBook displayNameForContact:value];
		Contact *contact = [LinphoneManager.instance.fastAddressBook.addressBookMap objectForKey:address];
		Boolean linphoneContact = (contact.friend && linphone_presence_model_get_basic_status(linphone_friend_get_presence_model(contact.friend)) == LinphonePresenceBasicStatusOpen);
		BOOL add = _allFilter || linphoneContact;

		if (((filter.length == 0)
				 || ([name.lowercaseString containsSubstring:filter.lowercaseString])
				 || ([address.lowercaseString containsSubstring:filter.lowercaseString]))
			&& add) {
			_contacts[address] = name;
		}
	}];
	// also add current entry, if not listed
	NSString *nsuri = filter.lowercaseString;
	LinphoneAddress *addr = [LinphoneUtils normalizeSipOrPhoneAddress:nsuri];
	if (addr) {
		char *uri = linphone_address_as_string(addr);
		nsuri = [NSString stringWithUTF8String:uri];
		ms_free(uri);
		linphone_address_destroy(addr);
	}
	if (nsuri.length > 0 && [_contacts valueForKey:nsuri] == nil) {
		_contacts[nsuri] = filter;
	}

	[self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.contacts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *kCellId = NSStringFromClass(UIChatCreateCell.class);
	UIChatCreateCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellId];
	if (cell == nil) {
		cell = [[UIChatCreateCell alloc] initWithIdentifier:kCellId];
	}
	cell.displayNameLabel.text = [_contacts.allValues objectAtIndex:indexPath.row];
	LinphoneAddress *addr = [LinphoneUtils normalizeSipOrPhoneAddress:[_contacts.allKeys objectAtIndex:indexPath.row]];
	Contact *contact = [LinphoneManager.instance.fastAddressBook.addressBookMap objectForKey:[_contacts.allKeys objectAtIndex:indexPath.row]];
	Boolean linphoneContact = (contact.friend && linphone_presence_model_get_basic_status(linphone_friend_get_presence_model(contact.friend)) == LinphonePresenceBasicStatusOpen);
	cell.linphoneImage.hidden = !linphoneContact;
	if (addr) {
		cell.addressLabel.text = [NSString stringWithUTF8String:linphone_address_as_string_uri_only(addr)];
	} else {
		cell.addressLabel.text = [_contacts.allKeys objectAtIndex:indexPath.row];
	}
	cell.selectedImage.hidden = ![_contactsGroup containsObject:cell.addressLabel.text];

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	UIChatCreateCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	if(cell.selectedImage.hidden) {
		if(![_contactsGroup containsObject:cell.addressLabel.text]) {
			[_contactsGroup addObject:cell.addressLabel.text];
			_contactsDict[cell.addressLabel.text] = cell.displayNameLabel.text;
			[_collectionView registerClass:UIChatCreateCollectionViewCell.class forCellWithReuseIdentifier:cell.addressLabel.text];
		}
	} else if([_contactsGroup containsObject:cell.addressLabel.text]) {
		[_contactsGroup removeObject:cell.addressLabel.text];
		[_contactsDict removeObjectForKey:cell.addressLabel.text];
	}
	cell.selectedImage.hidden = !cell.selectedImage.hidden;
	[_collectionView reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
	searchBar.showsCancelButton = (searchText.length > 0);
	[self reloadDataWithFilter:searchText];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
	[searchBar setShowsCancelButton:FALSE animated:TRUE];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
	[searchBar setShowsCancelButton:(searchBar.text.length > 0) animated:TRUE];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	[searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	[searchBar resignFirstResponder];
}
@end
